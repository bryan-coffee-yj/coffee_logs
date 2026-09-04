import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_log.dart';
import '../models/coffee_bean.dart';
import '../databases/database_helper.dart';
import 'home_feed_provider.dart'; // NEW: Needed to refresh the Home Timeline!

final brewLogProvider = FutureProvider.family<List<BrewLog>, int>((
  ref,
  beanId,
) async {
  return await DatabaseHelper.instance.getBrewLogsForBean(beanId);
});

class BrewLogController {
  static Future<void> addLog(
    WidgetRef ref,
    BrewLog log,
    CoffeeBean bean,
  ) async {
    // 1. Save the brew log to SQLite
    await DatabaseHelper.instance.insertBrewLog(log);

    // 2. Inventory math
    double newWeight = bean.currentWeight - log.dose;
    if (newWeight < 0) newWeight = 0;

    // 3. FIXED: Preserves your custom Process, Archive status, and Notes!
    final updatedBean = CoffeeBean(
      id: bean.id,
      roasterName: bean.roasterName,
      beanName: bean.beanName,
      roastLevel: bean.roastLevel,
      process: bean
          .process, // <--- FIXED: Now preserves Extended Natural, Thermal Shock, etc.!
      roastDate: bean.roastDate,
      price: bean.price,
      initialWeight: bean.initialWeight,
      currentWeight: newWeight,
      isArchived: bean.isArchived,
      archiveStatus: bean.archiveStatus,
      archiveNotes: bean.archiveNotes,
    );
    await DatabaseHelper.instance.updateCoffeeBean(updatedBean);

    // 4. Invalidate providers to refresh the UI immediately!
    ref.invalidate(brewLogProvider(log.beanId)); // Refreshes bean history
    ref.invalidate(
      homeFeedProvider,
    ); // <--- FIXED: Refreshes Home Feed instantly!
  }

  static Future<void> deleteLog(WidgetRef ref, int logId, int beanId) async {
    await DatabaseHelper.instance.deleteBrewLog(logId);

    // Invalidate both lists on delete as well
    ref.invalidate(brewLogProvider(beanId));
    ref.invalidate(homeFeedProvider); // Refreshes Home Feed on delete!
  }
}

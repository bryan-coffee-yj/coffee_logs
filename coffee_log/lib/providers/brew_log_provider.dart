import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_log.dart';
import '../models/coffee_bean.dart';
import '../databases/database_helper.dart';
import 'home_feed_provider.dart';
import 'bean_provider.dart';

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

    // 3. Preserves custom Process, Archive status, and Notes
    final updatedBean = CoffeeBean(
      id: bean.id,
      roasterName: bean.roasterName,
      beanName: bean.beanName,
      roastLevel: bean.roastLevel,
      process: bean.process,
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
    ref.invalidate(brewLogProvider(log.beanId));
    ref.invalidate(homeFeedProvider);
    ref.invalidate(beanProvider);
  }

  static Future<void> updateLog(
    WidgetRef ref,
    BrewLog updatedLog,
    double previousDose,
    CoffeeBean bean,
  ) async {
    // 1. Update the brew log in SQLite
    await DatabaseHelper.instance.updateBrewLog(updatedLog);

    // 2. Adjust inventory by dose difference
    final double doseDiff = updatedLog.dose - previousDose;
    double newWeight = bean.currentWeight - doseDiff;
    if (newWeight < 0) newWeight = 0;

    final updatedBean = CoffeeBean(
      id: bean.id,
      roasterName: bean.roasterName,
      beanName: bean.beanName,
      roastLevel: bean.roastLevel,
      process: bean.process,
      roastDate: bean.roastDate,
      price: bean.price,
      initialWeight: bean.initialWeight,
      currentWeight: newWeight,
      isArchived: bean.isArchived,
      archiveStatus: bean.archiveStatus,
      archiveNotes: bean.archiveNotes,
    );
    await DatabaseHelper.instance.updateCoffeeBean(updatedBean);

    // 3. Refresh providers
    ref.invalidate(brewLogProvider(updatedLog.beanId));
    ref.invalidate(homeFeedProvider);
    ref.invalidate(beanProvider);
  }

  static Future<void> deleteLog(WidgetRef ref, int logId, int beanId) async {
    // 1. Fetch the log to get the dose to refund
    final log = await DatabaseHelper.instance.getBrewLogById(logId);
    if (log != null) {
      final bean = await DatabaseHelper.instance.getCoffeeBeanById(beanId);
      if (bean != null) {
        final double refundedWeight = bean.currentWeight + log.dose;
        final updatedBean = CoffeeBean(
          id: bean.id,
          roasterName: bean.roasterName,
          beanName: bean.beanName,
          roastLevel: bean.roastLevel,
          process: bean.process,
          roastDate: bean.roastDate,
          price: bean.price,
          initialWeight: bean.initialWeight,
          currentWeight: refundedWeight,
          isArchived: bean.isArchived,
          archiveStatus: bean.archiveStatus,
          archiveNotes: bean.archiveNotes,
        );
        await DatabaseHelper.instance.updateCoffeeBean(updatedBean);
      }
    }

    // 2. Delete log from SQLite
    await DatabaseHelper.instance.deleteBrewLog(logId);

    // 3. Invalidate providers
    ref.invalidate(brewLogProvider(beanId));
    ref.invalidate(homeFeedProvider);
    ref.invalidate(beanProvider);
  }
}

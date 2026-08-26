import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_log.dart';
import '../models/coffee_bean.dart'; // Needed for inventory math
import '../databases/database_helper.dart';

final brewLogProvider = FutureProvider.family<List<BrewLog>, int>((ref, beanId) async {
  return await DatabaseHelper.instance.getBrewLogsForBean(beanId);
});

class BrewLogController {
  
  // Notice we now require the CoffeeBean so we can deduct the dose!
  static Future<void> addLog(WidgetRef ref, BrewLog log, CoffeeBean bean) async {
    // 1. Save the brew log
    await DatabaseHelper.instance.insertBrewLog(log);
    
    // 2. Do the Barista Math (Deduct dose from current weight)
    double newWeight = bean.currentWeight - log.dose;
    if (newWeight < 0) newWeight = 0; // Ensures we never have negative beans
    
    // 3. Save the new weight back to the bean database
    final updatedBean = CoffeeBean(
      id: bean.id,
      roasterName: bean.roasterName,
      beanName: bean.beanName,
      roastLevel: bean.roastLevel,
      roastDate: bean.roastDate,
      price: bean.price,
      initialWeight: bean.initialWeight,
      currentWeight: newWeight,
    );
    await DatabaseHelper.instance.updateCoffeeBean(updatedBean);

    // 4. Tell the app to refresh the history screen
    ref.invalidate(brewLogProvider(log.beanId));
  }

  static Future<void> deleteLog(WidgetRef ref, int logId, int beanId) async {
    await DatabaseHelper.instance.deleteBrewLog(logId);
    ref.invalidate(brewLogProvider(beanId));
  }
}
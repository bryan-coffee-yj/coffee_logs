import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bean.dart';
import '../databases/database_helper.dart';

// --- 1. ACTIVE BEANS NOTIFIER (My Coffee Cellar) ---
class BeanNotifier extends AsyncNotifier<List<CoffeeBean>> {
  @override
  Future<List<CoffeeBean>> build() async {
    // This automatically fetches and populates the active stash!
    return await DatabaseHelper.instance.getActiveCoffeeBeans();
  }

  Future<void> addBean(CoffeeBean bean) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.insertCoffeeBean(bean);
      return await DatabaseHelper.instance.getActiveCoffeeBeans();
    });
  }

  Future<void> updateBean(CoffeeBean bean) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.updateCoffeeBean(bean);
      return await DatabaseHelper.instance.getActiveCoffeeBeans();
    });
  }

  Future<void> deleteBean(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.deleteCoffeeBean(id);
      return await DatabaseHelper.instance.getActiveCoffeeBeans();
    });
  }
}

// Global provider for Active Beans
final beanProvider = AsyncNotifierProvider<BeanNotifier, List<CoffeeBean>>(() {
  return BeanNotifier();
});

// --- 2. ARCHIVED BEANS NOTIFIER (Excel-style history) ---
class ArchiveNotifier extends AsyncNotifier<List<CoffeeBean>> {
  @override
  Future<List<CoffeeBean>> build() async {
    return await DatabaseHelper.instance.getArchivedCoffeeBeans();
  }

  Future<void> archiveBean(CoffeeBean bean) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.updateCoffeeBean(bean);

      // We invalidate the active bean list as well so the home screen updates instantly!
      ref.invalidate(beanProvider);

      return await DatabaseHelper.instance.getArchivedCoffeeBeans();
    });
  }
}

// Global provider for Archived Beans
final archiveProvider =
    AsyncNotifierProvider<ArchiveNotifier, List<CoffeeBean>>(() {
      return ArchiveNotifier();
    });

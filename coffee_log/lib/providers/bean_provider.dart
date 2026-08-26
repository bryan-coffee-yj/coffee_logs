import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bean.dart';
import '../databases/database_helper.dart';

// 1. Create the modern AsyncNotifier
class BeanNotifier extends AsyncNotifier<List<CoffeeBean>> {
  // The build method automatically runs when the app starts.
  // It handles setting the state to "loading" and then "data" automatically!
  @override
  Future<List<CoffeeBean>> build() async {
    return await DatabaseHelper.instance.getAllCoffeeBeans();
  }

  // Add a bean and refresh the list
  Future<void> addBean(CoffeeBean bean) async {
    // Set state to loading while we write to the database
    state = const AsyncValue.loading();

    // AsyncValue.guard automatically catches any errors and updates the state
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.insertCoffeeBean(bean);
      return await DatabaseHelper.instance.getAllCoffeeBeans();
    });
  }

  // Delete a bean and refresh the list
  Future<void> deleteBean(int id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.deleteCoffeeBean(id);
      return await DatabaseHelper.instance.getAllCoffeeBeans();
    });
  }
}

// 2. Create the Provider using AsyncNotifierProvider
final beanProvider = AsyncNotifierProvider<BeanNotifier, List<CoffeeBean>>(() {
  return BeanNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_method.dart';
import '../databases/database_helper.dart';

class MethodNotifier extends AsyncNotifier<List<BrewMethod>> {
  @override
  Future<List<BrewMethod>> build() async {
    return await DatabaseHelper.instance.getAllBrewMethods();
  }

  Future<void> addMethod(BrewMethod method) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.insertBrewMethod(method);
      return await DatabaseHelper.instance.getAllBrewMethods();
    });
  }

  Future<void> deleteMethod(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.deleteBrewMethod(id);
      return await DatabaseHelper.instance.getAllBrewMethods();
    });
  }
}

final methodProvider = AsyncNotifierProvider<MethodNotifier, List<BrewMethod>>(
  () {
    return MethodNotifier();
  },
);

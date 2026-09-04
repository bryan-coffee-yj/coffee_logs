import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_log.dart';
import '../databases/database_helper.dart';

// Provider to fetch ALL logs across all beans
final homeFeedProvider = FutureProvider<List<BrewLog>>((ref) async {
  return await DatabaseHelper.instance.getAllBrewLogs();
});

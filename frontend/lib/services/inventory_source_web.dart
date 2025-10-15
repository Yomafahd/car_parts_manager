import '../simple_database.dart';

Future<List<Map<String, dynamic>>> fetchAllInventoryItems() async {
  try {
    return await SimpleDatabase.getItems();
  } catch (_) {
    return [];
  }
}

import '../database/database_helper.dart';

Future<List<Map<String, dynamic>>> fetchAllInventoryItems() async {
  final db = DatabaseHelper();
  try {
    return await db.getAllItems();
  } catch (_) {
    return [];
  }
}

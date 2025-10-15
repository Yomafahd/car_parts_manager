// A minimal web implementation that avoids importing sqlite-backed packages
// to work around current `package:web` JS interop incompatibilities.
// You can replace this with a web-friendly store (e.g., sembast_web) later.

import '../models/inventory_item.dart';

class DatabaseHelper {
  Future<void> _unsupported() async {
    throw UnsupportedError(
      'Database is temporarily unsupported on Flutter Web due to JS interop issues. '
      'Please run on Windows desktop or Android for now.',
    );
  }

  Future<dynamic> get database async => _unsupported();

  Future<bool> insertItem(InventoryItem item) async {
    await _unsupported();
    return false;
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    await _unsupported();
    return [];
  }
}

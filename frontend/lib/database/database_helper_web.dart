// Web implementation using Backend API
// Now fully functional for Flutter Web! 🎉

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventory_item.dart';

/// Database Helper for Web - uses Backend API instead of SQLite
class DatabaseHelper {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/inventory';
  static const String _apiKey = 'car_parts_full_access';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'X-API-Key': _apiKey,
  };

  /// Get all inventory items from backend
  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['items'] ?? []);
        }
      }
      
      print('❌ Failed to get items: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting items: $e');
      return [];
    }
  }

  /// Insert a new item to backend
  Future<bool> insertItem(InventoryItem item) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(item.toMap()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Item added successfully: ${item.name}');
          return true;
        }
      }
      
      print('❌ Failed to add item: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error adding item: $e');
      return false;
    }
  }

  /// Update an existing item in backend
  Future<bool> updateItem(InventoryItem item) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${item.id}'),
        headers: _headers,
        body: json.encode(item.toMap()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Item updated successfully: ${item.name}');
          return true;
        }
      }
      
      print('❌ Failed to update item: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error updating item: $e');
      return false;
    }
  }

  /// Delete an item from backend
  Future<bool> deleteItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Item deleted successfully');
          return true;
        }
      }
      
      print('❌ Failed to delete item: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error deleting item: $e');
      return false;
    }
  }

  /// Get database reference (for compatibility with existing code)
  /// Returns a placeholder since we're using API
  Future<dynamic> get database async {
    return Future.value('API_MODE');
  }
}

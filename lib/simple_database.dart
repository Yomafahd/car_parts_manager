import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SimpleDatabase {
  static const String _storageKey = 'car_parts_inventory';

  static Future<void> addItem(Map<String, dynamic> item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allItems = await getItems();
      allItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...item,
      });
      await prefs.setString(_storageKey, json.encode(allItems));
      // ignore: avoid_print
      print('✅ تم الحفظ الدائم: ${item['name']} - إجمالي القطع: ${allItems.length}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ خطأ في الحفظ الدائم: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString(_storageKey);
      if (itemsJson == null) return [];
      final List<dynamic> raw = json.decode(itemsJson) as List<dynamic>;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ خطأ في قراءة البيانات: $e');
      return [];
    }
  }

  static Future<int> getItemsCount() async {
    final items = await getItems();
    return items.length;
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      // ignore: avoid_print
      print('🗑️ تم مسح كل البيانات');
    } catch (e) {
      // ignore: avoid_print
      print('❌ خطأ في المسح: $e');
    }
  }

  static Future<bool> deleteItemById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getItems();
      final before = items.length;
      items.removeWhere((e) => (e['id']?.toString() ?? '') == id);
      await prefs.setString(_storageKey, json.encode(items));
      // ignore: avoid_print
      print('🗑️ حذف عنصر (ويب): $id (قبل: $before، بعد: ${items.length})');
      return items.length < before;
    } catch (e) {
      // ignore: avoid_print
      print('❌ خطأ في الحذف (ويب): $e');
      return false;
    }
  }

  static Future<bool> updateItemById(String id, Map<String, dynamic> newData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getItems();
      bool updated = false;
      for (var i = 0; i < items.length; i++) {
        if ((items[i]['id']?.toString() ?? '') == id) {
          items[i] = {
            ...items[i],
            ...newData,
            'id': id,
          };
          updated = true;
          break;
        }
      }
      if (updated) {
        await prefs.setString(_storageKey, json.encode(items));
        // ignore: avoid_print
        print('✏️ تحديث عنصر (ويب): $id');
      }
      return updated;
    } catch (e) {
      // ignore: avoid_print
      print('❌ خطأ في التحديث (ويب): $e');
      return false;
    }
  }
}

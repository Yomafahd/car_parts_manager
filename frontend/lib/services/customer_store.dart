import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';

class CustomerStore {
  static const _kKey = 'customers_store_v1';

  static Future<List<Customer>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = (json.decode(raw) as List).cast<Map>();
      return list.map((m) => Customer.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Customer> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, json.encode(list.map((e) => e.toMap()).toList()));
  }

  static Future<void> upsert(Customer c) async {
    final list = await getAll();
    final idx = list.indexWhere((e) => e.id == c.id);
    if (idx == -1) {
      list.add(c);
    } else {
      list[idx] = c;
    }
    await _saveAll(list);
  }

  static Future<void> remove(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await _saveAll(list);
  }
}

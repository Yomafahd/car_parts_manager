import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/service_center.dart';

class ServiceCenterStore {
  static const _kKey = 'service_centers_store_v1';

  static Future<List<ServiceCenter>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = (json.decode(raw) as List).cast<Map>();
      return list.map((m) => ServiceCenter.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<ServiceCenter> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, json.encode(list.map((e) => e.toMap()).toList()));
  }

  static Future<void> upsert(ServiceCenter c) async {
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

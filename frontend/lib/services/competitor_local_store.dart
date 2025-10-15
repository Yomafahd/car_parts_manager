import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CompetitorLocalStore {
  static const _kKey = 'custom_competitors_list';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = (json.decode(raw) as List).cast<Map>();
      return list.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, json.encode(list));
  }

  static Future<void> addMany(List<Map<String, dynamic>> items) async {
    final curr = await load();
    // Avoid duplicates by name
    final names = curr.map((e) => (e['name'] ?? '').toString()).toSet();
    for (final it in items) {
      final n = (it['name'] ?? '').toString();
      if (n.isEmpty || names.contains(n)) continue;
      curr.add(it);
    }
    await save(curr);
  }
}

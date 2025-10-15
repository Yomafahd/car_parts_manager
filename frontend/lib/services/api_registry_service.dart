import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiProviderConfig {
  final String id; // unique id
  String name; // display name
  String key; // provider key, e.g., 'openrouter', 'huggingface'
  String category; // e.g., 'vision', 'chat', 'json', 'competitors'
  bool enabled;

  ApiProviderConfig({
    required this.id,
    required this.name,
    required this.key,
    required this.category,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'key': key,
        'category': category,
        'enabled': enabled,
      };

  factory ApiProviderConfig.fromMap(Map<String, dynamic> m) => ApiProviderConfig(
        id: m['id'] as String,
        name: m['name'] as String,
        key: m['key'] as String,
        category: m['category'] as String? ?? 'general',
        enabled: (m['enabled'] as bool?) ?? true,
      );
}

class ApiRegistryService {
  static const _kRegistryKey = 'api_registry_list';
  static const _kMasterEnabledKey = 'api_master_enabled';

  static Future<bool> isMasterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMasterEnabledKey) ?? true; // default enabled
  }

  static Future<void> setMasterEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMasterEnabledKey, value);
  }

  static Future<List<ApiProviderConfig>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRegistryKey);
    if (raw == null) {
      // seed defaults
      final defaults = <ApiProviderConfig>[
        ApiProviderConfig(id: 'openrouter', name: 'OpenRouter', key: 'openrouter', category: 'vision', enabled: true),
        ApiProviderConfig(id: 'huggingface', name: 'Hugging Face', key: 'huggingface', category: 'vision', enabled: false),
        ApiProviderConfig(id: 'openai', name: 'OpenAI', key: 'openai', category: 'vision', enabled: false),
        ApiProviderConfig(id: 'stability', name: 'Stability AI', key: 'stability', category: 'vision', enabled: false),
      ];
      await _saveAll(defaults);
      return defaults;
    }
    try {
      final list = (json.decode(raw) as List<dynamic>).cast<Map>();
      return list.map((m) => ApiProviderConfig.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<ApiProviderConfig> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRegistryKey, json.encode(list.map((e) => e.toMap()).toList()));
  }

  static Future<List<ApiProviderConfig>> getAll() => _loadAll();

  static Future<List<ApiProviderConfig>> getEnabled({String? category}) async {
    final all = await _loadAll();
    return all.where((e) => e.enabled && (category == null || e.category == category)).toList();
  }

  static Future<void> add(ApiProviderConfig cfg) async {
    final all = await _loadAll();
    // prevent dup id
    all.removeWhere((e) => e.id == cfg.id);
    all.add(cfg);
    await _saveAll(all);
  }

  static Future<void> update(ApiProviderConfig cfg) async {
    final all = await _loadAll();
    final idx = all.indexWhere((e) => e.id == cfg.id);
    if (idx != -1) {
      all[idx] = cfg;
      await _saveAll(all);
    }
  }

  static Future<void> remove(String id) async {
    final all = await _loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  static Future<void> setEnabled(String id, bool enabled) async {
    final all = await _loadAll();
    final idx = all.indexWhere((e) => e.id == id);
    if (idx != -1) {
      all[idx].enabled = enabled;
      await _saveAll(all);
    }
  }
}

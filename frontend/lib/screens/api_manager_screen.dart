import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_registry_service.dart';

class ApiManagerScreen extends StatefulWidget {
  const ApiManagerScreen({super.key});

  @override
  State<ApiManagerScreen> createState() => _ApiManagerScreenState();
}

class _ApiManagerScreenState extends State<ApiManagerScreen> {
  bool _loading = true;
  bool _masterEnabled = true;
  List<ApiProviderConfig> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = AuthService.currentUser;
    if (me == null || (me.role != UserRole.owner && me.role != UserRole.manager)) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صلاحيات غير كافية')));
      }
      return;
    }
    final enabled = await ApiRegistryService.isMasterEnabled();
    final list = await ApiRegistryService.getAll();
    if (!mounted) return;
    setState(() {
      _masterEnabled = enabled;
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({ApiProviderConfig? existing}) async {
    final idCtrl = TextEditingController(text: existing?.id ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    String category = existing?.category ?? 'vision';
    bool enabled = existing?.enabled ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة API' : 'تعديل API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'ID (فريد)')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم المعروض')),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'المزوّد (مثال: openrouter)')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: category,
                items: const [
                  DropdownMenuItem(value: 'vision', child: Text('Vision')),
                  DropdownMenuItem(value: 'chat', child: Text('Chat')),
                  DropdownMenuItem(value: 'json', child: Text('JSON/Extraction')),
                  DropdownMenuItem(value: 'competitors', child: Text('Competitors')),
                  DropdownMenuItem(value: 'general', child: Text('General')),
                ],
                onChanged: (v) => category = v ?? 'general',
                decoration: const InputDecoration(labelText: 'الفئة'),
              ),
              SwitchListTile(
                value: enabled,
                onChanged: (v) => enabled = v,
                title: const Text('مفعّل'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    final cfg = ApiProviderConfig(id: idCtrl.text.trim(), name: nameCtrl.text.trim(), key: keyCtrl.text.trim(), category: category, enabled: enabled);
    if (existing == null) {
      await ApiRegistryService.add(cfg);
    } else {
      await ApiRegistryService.update(cfg);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مزوّدي APIs'),
        actions: [
          IconButton(onPressed: () => _addOrEdit(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  value: _masterEnabled,
                  onChanged: (v) async {
                    setState(() => _masterEnabled = v);
                    await ApiRegistryService.setMasterEnabled(v);
                  },
                  title: const Text('تمكين جميع الواجهات (Master Switch)'),
                  subtitle: const Text('إيقاف هذا الخيار يعطّل كل الاستدعاءات الخارجية من التطبيق'),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (ctx, i) {
                      final it = _items[i];
                      return ListTile(
                        title: Text(it.name),
                        subtitle: Text('${it.key} • ${it.category}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: it.enabled,
                              onChanged: (v) async {
                                await ApiRegistryService.setEnabled(it.id, v);
                                _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _addOrEdit(existing: it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await ApiRegistryService.remove(it.id);
                                _load();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemCount: _items.length,
                  ),
                ),
              ],
            ),
    );
  }
}

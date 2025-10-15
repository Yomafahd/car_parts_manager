import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../simple_database.dart';
import '../services/media_ai_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  final List<String> _categories = const [
    'الكل', 'محرك', 'ناقل حركة', 'مكابح', 'كهرباء', 'هيكل', 'ديكور', 'أخرى'
  ];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() async => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final items = List<Map<String, dynamic>>.from(await SimpleDatabase.getItems());
    items.sort((a, b) {
      final da = _parseDate(a['time']);
      final db = _parseDate(b['time']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _items;
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    if (_selectedCategory != 'الكل') {
      filtered = filtered.where((item) {
        final itemCat = (item['category'] ?? '').toString();
        return itemCat == _selectedCategory;
      }).toList();
    }
    setState(() => _filteredItems = filtered);
  }

  void _filterItems() => _applyFilters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المخزون - ${_filteredItems.length} قطعة (ويب)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'مسح كل البيانات',
            onPressed: _clearData,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildQuickFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _empty()
                    : _buildItemsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _empty() => const Center(
        child: Text('لا توجد قطع في المخزون'),
      );

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '🔍 ابحث عن قطعة بالاسم أو الوصف...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterItems();
                  },
                )
              : null,
        ),
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
          _filterItems();
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'الكل';
                });
                _filterItems();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, i) {
        final item = _filteredItems[i];
        final String? cat = (item['category'] as String?)?.isEmpty == true ? null : item['category'] as String?;
        return Dismissible(
          key: Key('${item['id'] ?? item['name'] ?? i}-$i'),
          background: Container(
            color: Colors.orange,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _editItem(item);
              return false;
            } else {
              return await _confirmDelete(item);
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: _getCategoryIcon(cat),
              title: Text((item['name'] ?? 'بدون اسم').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if ((item['status']?.toString().isNotEmpty ?? false))
                        Chip(label: Text(item['status'].toString())),
                      if ((item['quality']?.toString().isNotEmpty ?? false))
                        Chip(label: Text('جودة: ${item['quality']}')),
                    ],
                  ),
                  Text('السعر (ج.م): ${_formatPrice(item['price'])}'),
                  if (cat != null && cat != 'أخرى') const SizedBox(height: 2),
                  if (cat != null && cat != 'أخرى') Text('الفئة: $cat', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: Text(_formatDate(item['time']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () => _showItemDetails(item),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${item['name'] ?? 'بدون اسم'}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await SimpleDatabase.deleteItemById((item['id'] ?? '').toString());
      if (ok) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ تم الحذف')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ تعذر الحذف')));
        }
      }
      return ok;
    }
    return false;
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: (item['name'] ?? '').toString());
    final priceController = TextEditingController(text: _formatPrice(item['price']));
    String selectedCategory = (item['category']?.toString().isNotEmpty ?? false) ? item['category'].toString() : 'أخرى';
    final descriptionController = TextEditingController(text: (item['description'] ?? '').toString());
    String status = (item['status'] ?? 'جديد').toString();
    String quality = (item['quality'] ?? 'جيد').toString();
    DateTime? scheduledDate = _parseDate(item['scheduledDate']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل القطعة'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم القطعة *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'السعر (ج.م)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'فئة القطعة', border: OutlineInputBorder()),
                  items: _categories.where((c) => c != 'الكل').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => selectedCategory = v ?? 'أخرى',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'جديد', child: Text('جديد')),
                    DropdownMenuItem(value: 'مستعمل', child: Text('مستعمل')),
                    DropdownMenuItem(value: 'مجدول', child: Text('مجدول')),
                  ],
                  onChanged: (v) => status = v ?? 'جديد',
                ),
                const SizedBox(height: 12),
                if (status == 'مجدول')
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'تاريخ الجدولة', border: OutlineInputBorder()),
                          child: Text(
                            scheduledDate == null
                                ? 'غير محدد'
                                : '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 2),
                            initialDate: scheduledDate ?? now,
                          );
                          if (picked != null) setState(() => scheduledDate = picked);
                        },
                        child: const Text('اختيار التاريخ'),
                      )
                    ],
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: quality,
                  decoration: const InputDecoration(labelText: 'الجودة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ممتاز', child: Text('ممتاز')),
                    DropdownMenuItem(value: 'جيد', child: Text('جيد')),
                    DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                    DropdownMenuItem(value: 'ضعيف', child: Text('ضعيف')),
                  ],
                  onChanged: (v) => quality = v ?? 'جيد',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        final rec = await MediaAIService.recognizePart(bytes);
                        if (rec['name'] != null && (nameController.text.isEmpty)) {
                          nameController.text = rec['name'] as String;
                        }
                        if (rec['category'] != null) {
                          final cat = rec['category'] as String;
                          if (_categories.contains(cat)) {
                            setState(() => selectedCategory = cat);
                          }
                        }
                        if (rec['status'] != null) setState(() => status = rec['status'] as String);
                        if (rec['quality'] != null) setState(() => quality = rec['quality'] as String);
                        if (rec['condition'] != null && descriptionController.text.isEmpty) {
                          descriptionController.text = rec['condition'] as String;
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعرّف الأولي على القطعة')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التعرّف: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('تعرّف تلقائي من صورة'),
                  ),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await SimpleDatabase.updateItemById(
                (item['id'] ?? '').toString(),
                {
                  'name': nameController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                  'category': selectedCategory,
                  'status': status,
                  'quality': quality,
                  if (scheduledDate != null) 'scheduledDate': scheduledDate!.toIso8601String(),
                  'description': descriptionController.text.trim(),
                },
              );
              if (!mounted) return;
              nav.pop();
              if (ok) {
                await _load();
                messenger.showSnackBar(const SnackBar(content: Text('✏️ تم التحديث')));
              } else {
                messenger.showSnackBar(const SnackBar(content: Text('❌ تعذر التحديث')));
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Icon _getCategoryIcon(String? category) {
    switch (category) {
      case 'محرك':
        return const Icon(Icons.engineering, color: Colors.orange);
      case 'ناقل حركة':
        return const Icon(Icons.settings, color: Colors.blue);
      case 'مكابح':
        return const Icon(Icons.stop_circle, color: Colors.red);
      case 'كهرباء':
        return Icon(Icons.electrical_services, color: Colors.yellow[700]);
      case 'هيكل':
        return const Icon(Icons.build, color: Colors.green);
      case 'ديكور':
        return const Icon(Icons.airline_seat_recline_normal, color: Colors.purple);
      default:
        return const Icon(Icons.inventory_2, color: Colors.blue);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // ignore parse errors
      }
    }
    return null;
  }

  String _formatDate(dynamic value) {
    final d = _parseDate(value);
    if (d == null) {
      return 'غير محدد';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatPrice(dynamic price) {
    double p;
    if (price is num) {
      p = price.toDouble();
    } else if (price is String) {
      p = double.tryParse(price) ?? 0;
    } else {
      p = 0;
    }
    return p.toStringAsFixed(2);
  }

  Future<void> _clearData() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد المسح'),
        content: const Text('هل أنت متأكد من مسح كل البيانات؟ لا يمكن التراجع عن هذا.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('مسح الكل', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await SimpleDatabase.clearAllData();
      await _load();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('✅ تم مسح كل البيانات بنجاح')));
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'أخرى';
    String status = 'جديد';
    String quality = 'جيد';
    final descriptionController = TextEditingController();
    DateTime? scheduledDate;

    await showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(ctx);
        return AlertDialog(
          title: const Text('إضافة قطعة جديدة'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم القطعة *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم القطعة' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'السعر (ج.م)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'فئة القطعة',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .where((c) => c != 'الكل')
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedCategory = v ?? 'أخرى'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'جديد', child: Text('جديد')),
                        DropdownMenuItem(value: 'مستعمل', child: Text('مستعمل')),
                        DropdownMenuItem(value: 'مجدول', child: Text('مجدول')),
                      ],
                      onChanged: (v) => setStateDialog(() => status = v ?? 'جديد'),
                    ),
                    const SizedBox(height: 12),
                    if (status == 'مجدول')
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الجدولة',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                scheduledDate == null
                                    ? 'غير محدد'
                                    : '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 2),
                                initialDate: scheduledDate ?? now,
                              );
                              if (picked != null) setStateDialog(() => scheduledDate = picked);
                            },
                            child: const Text('اختيار التاريخ'),
                          )
                        ],
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: quality,
                      decoration: const InputDecoration(labelText: 'الجودة', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ممتاز', child: Text('ممتاز')),
                        DropdownMenuItem(value: 'جيد', child: Text('جيد')),
                        DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                        DropdownMenuItem(value: 'ضعيف', child: Text('ضعيف')),
                      ],
                      onChanged: (v) => setStateDialog(() => quality = v ?? 'جيد'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'الوصف/الحالة', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 85,
                            );
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            final rec = await MediaAIService.recognizePart(bytes);
                            if (rec['name'] != null && (nameController.text.isEmpty)) {
                              nameController.text = rec['name'] as String;
                            }
                            if (rec['category'] != null) {
                              final cat = rec['category'] as String;
                              if (_categories.contains(cat)) {
                                setStateDialog(() => selectedCategory = cat);
                              }
                            }
                            if (rec['status'] != null) setStateDialog(() => status = rec['status'] as String);
                            if (rec['quality'] != null) setStateDialog(() => quality = rec['quality'] as String);
                            if (rec['condition'] != null && descriptionController.text.isEmpty) {
                              descriptionController.text = rec['condition'] as String;
                            }
                            messenger.showSnackBar(const SnackBar(content: Text('تم التعرّف الأولي على القطعة')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('تعذر التعرّف: $e')));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('تعرّف تلقائي من صورة'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => nav.pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                await SimpleDatabase.addItem({
                  'name': name,
                  'price': price,
                  'time': DateTime.now().toIso8601String(),
                  'category': selectedCategory,
                  'status': status,
                  'quality': quality,
                  'description': descriptionController.text.trim(),
                  if (scheduledDate != null) 'scheduledDate': scheduledDate!.toIso8601String(),
                });
                nav.pop();
                await _load();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('✅ تمت الإضافة بنجاح!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفاصيل القطعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم: ${item['name'] ?? 'غير محدد'}'),
            const SizedBox(height: 8),
            Text('السعر (ج.م): ${_formatPrice(item['price'])}'),
            const SizedBox(height: 8),
            Text('الوقت: ${_formatDate(item['time'])}'),
            const SizedBox(height: 8),
            if ((item['status']?.toString().isNotEmpty ?? false)) Text('الحالة: ${item['status']}'),
            if ((item['quality']?.toString().isNotEmpty ?? false)) Text('الجودة: ${item['quality']}'),
            if ((item['scheduledDate']?.toString().isNotEmpty ?? false)) Text('تاريخ الجدولة: ${_formatDate(item['scheduledDate'])}'),
            if ((item['description']?.toString().isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text('الوصف: ${item['description']}'),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

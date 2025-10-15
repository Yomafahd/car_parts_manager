import 'package:flutter/material.dart';

import '../simple_database.dart';

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

  // Alias for naming parity with snippet
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
                  Text('السعر: ${_formatPrice(item['price'])} د.إ'),
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
                  decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'فئة القطعة', border: OutlineInputBorder()),
                  items: _categories.where((c) => c != 'الكل').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => selectedCategory = v ?? 'أخرى',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                ),
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

    await showDialog(
      context: context,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(ctx);
        return AlertDialog(
          title: const Text('إضافة قطعة جديدة'),
          content: Form(
            key: _formKey,
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
                    labelText: 'السعر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => DropdownButtonFormField<String>(
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
                ),
              ],
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
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': name,
                  'price': price,
                  'time': DateTime.now().toIso8601String(),
                  'category': selectedCategory,
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
            Text('السعر: ${_formatPrice(item['price'])} د.إ'),
            const SizedBox(height: 8),
            Text('الوقت: ${_formatDate(item['time'])}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

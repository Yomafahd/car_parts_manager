import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/inventory_item.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String _selectedCategory = 'محرك';
  final List<String> _categories = [
    'محرك', 'ناقل حركة', 'مكابح', 'كهرباء', 'هيكل', 'ديكور', 'أخرى'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _chassisController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة قطعة جديدة'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              // سيتم إضافة شاشة العرض لاحقاً
              debugPrint('الذهاب إلى قائمة المخزون');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم القطعة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم القطعة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'وصف القطعة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _chassisController,
                decoration: InputDecoration(
                  labelText: 'رقم الشاصي / التسلسلي',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? _selectedCategory;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'فئة القطعة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر التكلفة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر البيع',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sell),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية المتاحة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[700],
                ),
                child: Text('حفظ القطعة', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      // عرض تحميل فوري
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري الحفظ... 🚀'))
      );

      // إنشاء كائن بسيط
      final newItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        chassisNumber: _chassisController.text,
        supplier: 'غير محدد',
        costPrice: _costController.text.isEmpty ? 0 : double.parse(_costController.text),
        sellingPrice: _priceController.text.isEmpty ? 0 : double.parse(_priceController.text),
        quantity: _quantityController.text.isEmpty ? 1 : int.parse(_quantityController.text),
        imageUrls: [],
        audioDescription: '',
        entryDate: DateTime.now(),
      );

      try {
        final dbHelper = DatabaseHelper();
        final success = await dbHelper.insertItem(newItem);
        
        // اختبار فوري: جلب كل القطع للتأكد
        final allItems = await dbHelper.getAllItems();
        debugPrint('القطع المخزنة حالياً: $allItems');

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم الحفظ! القطع في DB: ${allItems.length}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            )
          );

          // مسح الحقول
          _nameController.clear();
          _descriptionController.clear();
          _chassisController.clear();
          _costController.clear();
          _priceController.clear();
          _quantityController.clear();
        } else {
          throw Exception('فشل في الحفظ');
        }
      
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          )
        );
      }
    }
  }
}


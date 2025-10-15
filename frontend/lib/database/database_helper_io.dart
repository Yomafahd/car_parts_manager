import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop (Windows/Linux/macOS)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'car_parts_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE inventory_items(
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            chassisNumber TEXT,
            supplier TEXT,
            costPrice REAL,
            sellingPrice REAL,
            quantity INTEGER,
            imageUrls TEXT,
            audioDescription TEXT,
            entryDate TEXT,
            status TEXT,
            quality TEXT,
            scheduledDate TEXT,
            condition TEXT
          )
        ''');
        // ignore: avoid_print
        print('✅ تم إنشاء قاعدة البيانات (IO) بنجاح');
      },
    );
  }

  Future<bool> insertItem(InventoryItem item) async {
    try {
      final db = await database;
      await db.insert('inventory_items', item.toMap());
      // ignore: avoid_print
      print('✅ (IO) تم حفظ القطعة: ${item.name}');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ (IO) خطأ في الحفظ: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final db = await database;
      final items = await db.query('inventory_items');
      // ignore: avoid_print
      print('✅ (IO) عدد القطع في قاعدة البيانات: ${items.length}');
      return items;
    } catch (e) {
      // ignore: avoid_print
      print('❌ (IO) خطأ في القراءة: $e');
      return [];
    }
  }

  Future<bool> deleteItemById(String id) async {
    try {
      final db = await database;
      final count = await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
      // ignore: avoid_print
      print('🗑️ (IO) حذف العناصر: $count للمعرف $id');
      return count > 0;
    } catch (e) {
      // ignore: avoid_print
      print('❌ (IO) خطأ في الحذف: $e');
      return false;
    }
  }

  Future<bool> updateItem(InventoryItem item) async {
    try {
      final db = await database;
      final count = await db.update(
        'inventory_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      // ignore: avoid_print
      print('✏️ (IO) تحديث العناصر: $count للمعرف ${item.id}');
      return count > 0;
    } catch (e) {
      // ignore: avoid_print
      print('❌ (IO) خطأ في التحديث: $e');
      return false;
    }
  }
}

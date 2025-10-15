import 'dart:convert';

class InventoryItem {
  String? id;
  String name;
  String? description;
  String? category;
  String? chassisNumber;
  String? supplier;
  double? costPrice;
  double? sellingPrice;
  int quantity;
  List<String>? imageUrls;
  String? audioDescription;
  DateTime? entryDate;
  // AI Inventory Manager fields
  String? status; // جديد/مستعمل/مجدول
  String? quality; // ممتاز/جيد/متوسط/ضعيف
  DateTime? scheduledDate; // في حال مجدول
  String? condition; // وصف حالة مختصر

  InventoryItem({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.chassisNumber,
    this.supplier,
    this.costPrice,
    this.sellingPrice,
    required this.quantity,
    this.imageUrls,
    this.audioDescription,
    this.entryDate,
    this.status,
    this.quality,
    this.scheduledDate,
    this.condition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'chassisNumber': chassisNumber,
      'supplier': supplier,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'imageUrls': imageUrls != null ? jsonEncode(imageUrls) : null,
      'audioDescription': audioDescription,
      'entryDate': entryDate?.toIso8601String(),
      'status': status,
      'quality': quality,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'condition': condition,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      chassisNumber: map['chassisNumber'] as String?,
      supplier: map['supplier'] as String?,
      costPrice: map['costPrice'] as double?,
      sellingPrice: map['sellingPrice'] as double?,
      quantity: map['quantity'] as int,
      imageUrls: map['imageUrls'] != null ? List<String>.from(jsonDecode(map['imageUrls'])) : null,
      audioDescription: map['audioDescription'] as String?,
      entryDate: map['entryDate'] != null ? DateTime.parse(map['entryDate']) : null,
      status: map['status'] as String?,
      quality: map['quality'] as String?,
      scheduledDate: map['scheduledDate'] != null ? DateTime.parse(map['scheduledDate']) : null,
      condition: map['condition'] as String?,
    );
  }
}

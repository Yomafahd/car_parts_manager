class Customer {
  String id;
  String name;
  String? phone;
  String? address;
  String? location; // e.g., 'lat,lon' or map link
  String? notes;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'location': location,
        'notes': notes,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        phone: (m['phone'] as String?)?.toString(),
        address: (m['address'] as String?)?.toString(),
        location: (m['location'] as String?)?.toString(),
        notes: (m['notes'] as String?)?.toString(),
      );
}

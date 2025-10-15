class ServiceCenter {
  String id;
  String name;
  String? phone;
  String? address;
  String? location;
  List<String> services;
  String? notes;

  ServiceCenter({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.location,
    this.services = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'location': location,
        'services': services,
        'notes': notes,
      };

  factory ServiceCenter.fromMap(Map<String, dynamic> m) => ServiceCenter(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        phone: (m['phone'] as String?)?.toString(),
        address: (m['address'] as String?)?.toString(),
        location: (m['location'] as String?)?.toString(),
        services: ((m['services'] as List?)?.map((e) => e.toString()).toList()) ?? [],
        notes: (m['notes'] as String?)?.toString(),
      );
}

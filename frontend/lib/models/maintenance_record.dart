class MaintenanceRecord {
  final String type; // e.g., oil_change, air_filter, brake_pads, spark_plugs, battery, coolant
  final DateTime date;
  final int odometerKm;
  final double? cost;
  final String? notes;

  const MaintenanceRecord({
    required this.type,
    required this.date,
    required this.odometerKm,
    this.cost,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'date': date.toIso8601String(),
        'odometerKm': odometerKm,
        'cost': cost,
        'notes': notes,
      };

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) => MaintenanceRecord(
        type: (map['type'] ?? '').toString(),
        date: DateTime.parse((map['date'] ?? DateTime.now().toIso8601String()).toString()),
        odometerKm: (map['odometerKm'] ?? 0) is int
            ? map['odometerKm'] as int
            : int.tryParse(map['odometerKm'].toString()) ?? 0,
        cost: map['cost'] == null
            ? null
            : (map['cost'] is num ? (map['cost'] as num).toDouble() : double.tryParse(map['cost'].toString())),
        notes: map['notes']?.toString(),
      );
}

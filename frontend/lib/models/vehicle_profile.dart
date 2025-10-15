class VehicleProfile {
  final String make;
  final String model;
  final int year;
  final int mileageKm; // current odometer reading
  final String drivingStyle; // city/highway/mixed/aggressive

  VehicleProfile({
    required this.make,
    required this.model,
    required this.year,
    required this.mileageKm,
    this.drivingStyle = 'mixed',
  });

  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'year': year,
        'mileageKm': mileageKm,
        'drivingStyle': drivingStyle,
      };

  factory VehicleProfile.fromMap(Map<String, dynamic> map) => VehicleProfile(
        make: (map['make'] ?? '').toString(),
        model: (map['model'] ?? '').toString(),
        year: (map['year'] ?? 0) is int
            ? map['year'] as int
            : int.tryParse(map['year'].toString()) ?? 0,
        mileageKm: (map['mileageKm'] ?? 0) is int
            ? map['mileageKm'] as int
            : int.tryParse(map['mileageKm'].toString()) ?? 0,
        drivingStyle: (map['drivingStyle'] ?? 'mixed').toString(),
      );
}

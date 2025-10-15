import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_profile.dart';
import '../models/maintenance_record.dart';

class PredictiveMaintenanceService {
  static const _vehicleKey = 'pm_vehicle_profile_v1';
  static const _logsKey = 'pm_maintenance_logs_v1';

  // Persistence
  static Future<void> saveVehicle(VehicleProfile v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(v.toMap()));
  }

  static Future<VehicleProfile?> loadVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_vehicleKey);
    if (s == null) return null;
    return VehicleProfile.fromMap(jsonDecode(s));
  }

  static Future<void> addLog(MaintenanceRecord r) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadLogs();
    list.add(r);
    await prefs.setString(_logsKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  static Future<List<MaintenanceRecord>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_logsKey);
    if (s == null) return [];
    final List<dynamic> raw = jsonDecode(s);
    return raw.map((m) => MaintenanceRecord.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  // Business logic
  /// Returns Arabic reminders like: "اقترب موعد تغيير الزيت" based on odometer and last logs.
  static List<String> computeReminders(VehicleProfile v, List<MaintenanceRecord> logs) {
    final tips = <String>[];

    int lastOilKm = _lastKmOf('oil_change', logs) ?? 0;
    int lastAirFilterKm = _lastKmOf('air_filter', logs) ?? 0;
    int lastBrakeKm = _lastKmOf('brake_pads', logs) ?? 0;
    int lastPlugsKm = _lastKmOf('spark_plugs', logs) ?? 0;

    // Intervals (heuristic defaults)
    const oilInterval = 10000; // 10k
    const airFilterInterval = 15000;
    const brakeInterval = 30000;
    const plugsInterval = 60000;

    if (v.mileageKm - lastOilKm >= (oilInterval - 1000)) {
      tips.add('اقترب موعد تغيير زيت المحرك وفلتر الزيت.');
    }
    if (v.mileageKm - lastAirFilterKm >= (airFilterInterval - 2000)) {
      tips.add('تحقّق من فلتر الهواء، قد يحتاج تنظيفاً أو استبدالاً.');
    }
    if (v.mileageKm - lastBrakeKm >= (brakeInterval - 3000)) {
      tips.add('افحص تيل/أقراص الفرامل، قد تكون بحاجة لاستبدال قريباً.');
    }
    if (v.mileageKm - lastPlugsKm >= (plugsInterval - 5000)) {
      tips.add('مراجعة شمعات الإشعال (بواجي) خلال الفترة القادمة.');
    }

    return tips.isEmpty ? ['لا توجد تنبيهات صيانة حالياً.'] : tips;
  }

  /// Rough cost estimation for upcoming routines, based on average costs.
  static double estimateUpcomingCost(VehicleProfile v, List<MaintenanceRecord> logs) {
    double cost = 0.0;
    int lastOilKm = _lastKmOf('oil_change', logs) ?? 0;
    int lastAirFilterKm = _lastKmOf('air_filter', logs) ?? 0;
    int lastBrakeKm = _lastKmOf('brake_pads', logs) ?? 0;
    int lastPlugsKm = _lastKmOf('spark_plugs', logs) ?? 0;

    if (v.mileageKm - lastOilKm >= 9000) cost += 180; // oil + filter rough
    if (v.mileageKm - lastAirFilterKm >= 13000) cost += 70; // air filter
    if (v.mileageKm - lastBrakeKm >= 27000) cost += 350; // pads/rotors rough
    if (v.mileageKm - lastPlugsKm >= 55000) cost += 250; // spark plugs set

    // Battery after ~4 years: simple heuristic
    final age = DateTime.now().year - v.year;
    if (age >= 4) cost += 300;

    return double.parse(cost.toStringAsFixed(2));
  }

  static int? _lastKmOf(String type, List<MaintenanceRecord> logs) {
    final filtered = logs.where((l) => l.type == type).toList()
      ..sort((a, b) => b.odometerKm.compareTo(a.odometerKm));
    return filtered.isEmpty ? null : filtered.first.odometerKm;
  }
}

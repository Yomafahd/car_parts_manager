import 'dart:math';

import '../models/vehicle_profile.dart';
import 'inventory_source.dart';

class RecommendationItem {
  final String title; // Arabic message
  final String? partId; // optional inventory id to navigate
  final String? category; // optional category hint

  const RecommendationItem({required this.title, this.partId, this.category});

  RecommendationItem copyWith({String? title, String? partId, String? category}) =>
      RecommendationItem(
        title: title ?? this.title,
        partId: partId ?? this.partId,
        category: category ?? this.category,
      );
}

class SmartRecommendationService {
  /// توصيات مبنية على موديل/سنة السيارة وعادات الصيانة
  /// - زيوت/فلاتر حسب عدد الكيلومترات
  /// - بطارية/بواجي عند تجاوز عمر أو مسافة
  /// - تيل/أقراص فرامل في القيادة داخل المدن بكثرة
  static Future<List<RecommendationItem>> recommend(
    VehicleProfile vehicle, {
    List<Map<String, dynamic>> maintenanceLogs = const [],
  }) async {
    final recs = <RecommendationItem>[];
    final nowYear = DateTime.now().year;
    final vehicleAge = (nowYear - vehicle.year).clamp(0, 50);
    final mileage = vehicle.mileageKm;
    final style = vehicle.drivingStyle.toLowerCase();

    // قواعد بسيطة مبنية على المسافة والسن
    if (mileage % 10000 >= 9000 || mileage == 0) {
      recs.add(RecommendationItem(title: 'اقترب موعد تغيير زيت المحرك وفلتر الزيت.', category: 'زيوت ومواد تشحيم'));
      recs.add(RecommendationItem(title: 'تحقّق من فلتر الهواء ونظافته.', category: 'فلاتر هواء ووقود'));
    }

    if (vehicleAge >= 4) {
      recs.add(RecommendationItem(title: 'فكّر في فحص البطارية وقد تحتاج استبدالاً.', category: 'أنظمة الكهرباء'));
    }

    if (mileage >= 60000) {
      recs.add(RecommendationItem(title: 'مراجعة شمعات الإشعال (بواجي) قد تكون مطلوبة.', category: 'بواجي'));
    }

    if (style.contains('city') || style.contains('mixed')) {
      recs.add(RecommendationItem(title: 'القيادة داخل المدن تستهلك تيل الفرامل أسرع—افحص السمك.', category: 'أنظمة الفرامل'));
    }

    // ربط التوصيات بعناصر حقيقية من المخزون
    final inventory = await fetchAllInventoryItems();
    if (inventory.isNotEmpty) {
      final rnd = Random();
      for (var i = 0; i < recs.length; i++) {
        final r = recs[i];
        final matches = inventory.where((m) {
          final cat = (m['category'] ?? '').toString();
          return r.category == null ? false : cat.contains(r.category!);
        }).toList();
        if (matches.isNotEmpty) {
          final pick = matches[rnd.nextInt(matches.length)];
          recs[i] = r.copyWith(partId: pick['id']?.toString());
        }
      }
    }

    return recs;
  }
}

import 'dart:async';
import 'dart:math' as math;


import '../models/inventory_item.dart';
import '../simple_database.dart';

/// محور تعلّم الآلة (هيكل تجريبي بدون حزم ML)
/// - trainCustomModel: يحاكي عملية تدريب نموذج ويعيد مؤشرات تدريب
/// - getSmartRecommendations: توصيات مبنية على بيانات المخزون الحالية
class MachineLearningHub {
  /// محاكاة تدريب نموذج: يرجع سجل خسارة/دقّة عبر عصور (epochs)
  static Future<TrainingReport> trainCustomModel({int epochs = 10}) async {
    final rnd = math.Random(42);
    final losses = <double>[];
    final acc = <double>[];
    var loss = 1.2;
    var accuracy = 0.45;
    for (int e = 0; e < epochs; e++) {
      await Future.delayed(const Duration(milliseconds: 80));
      // تناقص تدريجي مع بعض الضوضاء
      loss = (loss * 0.85) + rnd.nextDouble() * 0.03;
      accuracy = (accuracy + 0.05 + rnd.nextDouble() * 0.02).clamp(0.0, 0.99);
      losses.add(double.parse(loss.toStringAsFixed(4)));
      acc.add(double.parse(accuracy.toStringAsFixed(4)));
    }
    return TrainingReport(epochs: epochs, losses: losses, accuracies: acc);
  }

  /// توصيات ذكية بسيطة من بيانات المخزون
  /// - قطع ذات هامش ربح منخفض: اقترح رفع السعر
  /// - أصناف منخفضة المخزون: اقترح إعادة طلب
  /// - فئات ذات مبيعات جيدة: اقترح توسيع التشكيلة
  static Future<List<String>> getSmartRecommendations() async {
  final items = await SimpleDatabase.getItems();
    if (items.isEmpty) {
      return ['لا توجد بيانات بعد. أضف بعض العناصر لبدء التوصيات.'];
    }

    // تحويل إلى InventoryItem إذا لزم
    final inv = items.map((m) => InventoryItem.fromMap(m)).toList();

    final tips = <String>[];

    // 1) هامش الربح
    for (final it in inv) {
      final cost = (it.costPrice ?? 0).toDouble();
      final sale = (it.sellingPrice ?? 0).toDouble();
      final margin = sale - cost;
      if (sale > 0 && margin / (sale == 0 ? 1 : sale) < 0.1) {
        tips.add('العنصر "${it.name}" يحقق هامش ربح منخفض. فكّر في تحسين التسعير.');
      }
    }

    // 2) مخزون منخفض
    for (final it in inv) {
      final q = it.quantity;
      if (q <= 2) {
        tips.add('المخزون منخفض للعنصر "${it.name}". يُنصح بإعادة الطلب.');
      }
    }

    // 3) تحليل فئات بسيط
    final byCat = <String, int>{};
    for (final it in inv) {
      final c = (it.category ?? 'غير مصنف');
      byCat[c] = (byCat[c] ?? 0) + it.quantity;
    }
    final sortedCats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedCats.isNotEmpty) {
      final top = sortedCats.first;
      tips.add('فئة "${top.key}" نشطة. وسّع التشكيلة لهذه الفئة.');
    }

    return tips.isEmpty
        ? ['البيانات الحالية لا توصي بتغييرات كبيرة. استمر بالمراقبة.']
        : tips;
  }
}

class TrainingReport {
  TrainingReport({required this.epochs, required this.losses, required this.accuracies});
  final int epochs;
  final List<double> losses;
  final List<double> accuracies;

  Map<String, dynamic> toMap() => {
        'epochs': epochs,
        'losses': losses,
        'accuracies': accuracies,
      };

  @override
  String toString() => 'TrainingReport(epochs: $epochs, losses: $losses, accuracies: $accuracies)';
}

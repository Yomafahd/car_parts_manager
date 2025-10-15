import '../simple_database.dart';

class AnalyticsService {
  // تحليل ربحية القطع
  static Future<Map<String, dynamic>> analyzeProfitability() async {
    final items = await SimpleDatabase.getItems();

    if (items.isEmpty) {
      return {
        'totalRevenue': 0.0,
        'totalCost': 0.0,
        'netProfit': 0.0,
        'profitMargin': 0.0,
        'mostProfitableItem': {'name': 'لا توجد بيانات', 'profit': 0.0, 'margin': 0.0},
        'categoryAnalysis': <String, double>{},
        'totalItems': 0,
        'analysisDate': DateTime.now(),
      };
    }

    double totalRevenue = 0.0;
    double totalCost = 0.0;
    Map<String, double> categoryAnalysis = {};
    Map<String, dynamic> mostProfitableItem = {
      'name': 'لا توجد بيانات',
      'profit': 0.0,
      'margin': 0.0,
    };

    for (final item in items) {
      final num costNum = (item['costPrice'] ?? 0) as num;
      final num priceNum = (item['sellingPrice'] ?? 0) as num;
      final int quantity = ((item['quantity'] ?? 0) as num).toInt();

      final double cost = costNum.toDouble();
      final double price = priceNum.toDouble();

      final double revenue = price * quantity;
      final double profit = revenue - (cost * quantity);
      final double profitMargin = (cost > 0 && quantity > 0)
          ? (profit / (cost * quantity)) * 100
          : 0.0;

      totalRevenue += revenue;
      totalCost += cost * quantity;

      if (profit > (mostProfitableItem['profit'] as double)) {
        mostProfitableItem = {
          'name': item['name'] ?? 'غير معروف',
          'profit': profit,
          'margin': profitMargin,
        };
      }

      final String category = (item['category'] as String?) ?? 'أخرى';
      categoryAnalysis[category] = (categoryAnalysis[category] ?? 0.0) + profit;
    }

    final double netProfit = totalRevenue - totalCost;
    final double profitMargin = totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;

    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'netProfit': netProfit,
      'profitMargin': profitMargin,
      'mostProfitableItem': mostProfitableItem,
      'categoryAnalysis': categoryAnalysis,
      'totalItems': items.length,
      'analysisDate': DateTime.now(),
    };
  }

  // تحليل اتجاهات المبيعات (مبسّط)
  static Future<Map<String, dynamic>> analyzeSalesTrends() async {
    final items = await SimpleDatabase.getItems();

    final recentItems = items.where((item) {
      final it = item['time'];
      if (it is String) {
        try {
          final date = DateTime.parse(it);
          return date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
        } catch (_) {
          return false;
        }
      }
      return false;
    }).toList();

    final int total = items.length;
    final int recent = recentItems.length;
    final double growthRate = total > 0 ? (recent / total) * 100 : 0.0;
    final String trend = recent > (total / 2) ? 'صاعد' : (recent == 0 ? 'غير واضح' : 'ثابت');

    return {
      'recentItemsCount': recent,
      'growthRate': growthRate,
      'trend': trend,
    };
  }

  // اكتشاف أنماط مبسّطة
  static Future<Map<String, dynamic>> detectPatterns() async {
    final items = await SimpleDatabase.getItems();
    final Map<String, int> categories = {};
    double totalValue = 0.0;

    for (final item in items) {
      final String category = (item['category'] as String?) ?? 'أخرى';
      categories[category] = (categories[category] ?? 0) + 1;

      final num priceNum = (item['sellingPrice'] ?? 0) as num;
      final int quantity = ((item['quantity'] ?? 0) as num).toInt();
      totalValue += priceNum.toDouble() * quantity;
    }

    final String dominantCategory = categories.isNotEmpty
        ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'لا توجد بيانات';

    return {
      'dominantCategory': dominantCategory,
      'categoryDistribution': categories,
      'totalInventoryValue': totalValue,
      'averageItemValue': items.isNotEmpty ? totalValue / items.length : 0.0,
    };
  }

  // تنبؤات بسيطة بناءً على البيانات الحالية
  static Future<Map<String, dynamic>> generatePredictions() async {
    final analytics = await analyzeProfitability();
    final trends = await analyzeSalesTrends();

    final double growth = (trends['growthRate'] as num?)?.toDouble() ?? 0.0;
    final double predictedGrowth = growth * 1.1; // نمو متحفظ 10%
    final double totalRevenue = (analytics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final double predictedRevenue = totalRevenue * (1 + (predictedGrowth / 100));

    return {
      'predictedRevenue': predictedRevenue,
      'predictedGrowth': predictedGrowth,
      'recommendation': _generateRecommendation(analytics, trends),
      'confidenceLevel': 0.75, // مستوى ثقة 75%
    };
  }

  static String _generateRecommendation(
      Map<String, dynamic> analytics, Map<String, dynamic> trends) {
    final double profitMargin = (analytics['profitMargin'] as num?)?.toDouble() ?? 0.0;
    final double growth = (trends['growthRate'] as num?)?.toDouble() ?? 0.0;

    if (profitMargin > 50 && growth > 20) {
      return 'أداء ممتاز! يُنصح بالتوسع تدريجيًا في الفئات الأكثر ربحية.';
    } else if (profitMargin < 20) {
      return 'هوامش الربح منخفضة. يُنصح بمراجعة التسعير وتخفيض التكلفة وتحسين إدارة المخزون.';
    } else if (growth < 10) {
      return 'معدل النمو بطيء. يُنصح بتجربة عروض ترويجية وتكثيف التسويق.';
    } else {
      return 'أداء جيد. الاستمرار على الإستراتيجية الحالية مع مراقبة المؤشرات.';
    }
  }
}

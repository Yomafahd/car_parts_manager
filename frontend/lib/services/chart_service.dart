import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'analytics_service.dart';

class ChartService {
  // رسم بياني للإيرادات والربح
  static Future<LineChartData> getRevenueChart() async {
    final analytics = await AnalyticsService.analyzeProfitability();
    final predictions = await AnalyticsService.generatePredictions();

    final double totalCost = (analytics['totalCost'] as num?)?.toDouble() ?? 0.0;
    final double totalRevenue = (analytics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final double netProfit = (analytics['netProfit'] as num?)?.toDouble() ?? 0.0;
    final double predictedRevenue = (predictions['predictedRevenue'] as num?)?.toDouble() ?? 0.0;

    final spots = <FlSpot>[
      FlSpot(0, totalCost),
      FlSpot(1, totalRevenue),
      FlSpot(2, netProfit),
      FlSpot(3, predictedRevenue),
    ];

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const titles = ['التكلفة', 'الإيراد', 'الربح', 'المتوقع'];
              final idx = value.toInt();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(idx >= 0 && idx < titles.length ? titles[idx] : ''),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          belowBarData: BarAreaData(show: false),
        ),
      ],
      minX: 0,
      maxX: 3,
    );
  }

  // رسم بياني دائري لتوزيع الفئات
  static Future<PieChartData> getCategoryDistributionChart() async {
    final analytics = await AnalyticsService.analyzeProfitability();
    final Map<String, double> categoryAnalysis =
        Map<String, double>.from((analytics['categoryAnalysis'] as Map?) ?? {});

    if (categoryAnalysis.isEmpty) {
      return PieChartData(sections: const []);
    }

    final total = categoryAnalysis.values.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) {
      return PieChartData(sections: const []);
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
    ];
    int colorIndex = 0;
    final sections = categoryAnalysis.entries.map((e) {
      final color = colors[colorIndex++ % colors.length];
      final percent = (e.value / total) * 100;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${e.key}\n${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
    );
  }

  // رسم بياني شريطي للأداء
  static Future<BarChartData> getPerformanceBarChart() async {
    final analytics = await AnalyticsService.analyzeProfitability();
    final double revenue = (analytics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final double cost = (analytics['totalCost'] as num?)?.toDouble() ?? 0.0;
    final double net = (analytics['netProfit'] as num?)?.toDouble() ?? 0.0;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(toY: revenue, color: Colors.green, width: 20),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(toY: cost, color: Colors.orange, width: 20),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(toY: net, color: Colors.blue, width: 20),
          ],
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const titles = ['الإيرادات', 'التكاليف', 'صافي الربح'];
              final idx = value.toInt();
              return Text(idx >= 0 && idx < titles.length ? titles[idx] : '');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
    );
  }
}

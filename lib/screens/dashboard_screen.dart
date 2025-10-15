import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/chart_service.dart';
import '../services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profitability;
  Map<String, dynamic>? _trends;
  Map<String, dynamic>? _patterns;
  Map<String, dynamic>? _predictions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await AnalyticsService.analyzeProfitability();
    final t = await AnalyticsService.analyzeSalesTrends();
    final d = await AnalyticsService.detectPatterns();
    final g = await AnalyticsService.generatePredictions();
    if (!mounted) return;
    setState(() {
      _profitability = p;
      _trends = t;
      _patterns = d;
      _predictions = g;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم الذكية'),
        backgroundColor: Colors.indigo,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (value) async {
              if (value == 'pdf') {
                await ExportService.exportToPDF();
              } else if (value == 'excel') {
                await ExportService.exportToExcel();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pdf', child: Text('📄 تصدير PDF')),
              PopupMenuItem(value: 'excel', child: Text('📊 تصدير Excel')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    title: 'الربحية',
                    child: _profitability == null
                        ? const Text('لا توجد بيانات')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('الإيرادات', _formatCurrency(_profitability!['totalRevenue'])),
                              _kv('التكلفة', _formatCurrency(_profitability!['totalCost'])),
                              _kv('صافي الربح', _formatCurrency(_profitability!['netProfit'])),
                              _kv('هامش الربح', _formatPercent(_profitability!['profitMargin'])),
                              const SizedBox(height: 8),
                              Text('الأكثر ربحية: ${_profitability!['mostProfitableItem']['name']} (${_formatCurrency(_profitability!['mostProfitableItem']['profit'])})'),
                            ],
                          ),
                  ),
                  _card(
                    title: 'الاتجاهات',
                    child: _trends == null
                        ? const Text('لا توجد بيانات')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('العناصر الحديثة (30 يوم)', _trends!['recentItemsCount']),
                              _kv('معدل النمو', _formatPercent(_trends!['growthRate'])),
                              _kv('الاتجاه', _trends!['trend']),
                            ],
                          ),
                  ),
                  _card(
                    title: 'الأنماط',
                    child: _patterns == null
                        ? const Text('لا توجد بيانات')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('الفئة المسيطرة', _patterns!['dominantCategory']),
                              _kv('قيمة المخزون الإجمالية', _formatCurrency(_patterns!['totalInventoryValue'])),
                              _kv('متوسط قيمة القطعة', _formatCurrency(_patterns!['averageItemValue'])),
                            ],
                          ),
                  ),
                  _card(
                    title: 'تنبؤات',
                    child: _predictions == null
                        ? const Text('لا توجد بيانات')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('الإيرادات المتوقعة', _formatCurrency(_predictions!['predictedRevenue'])),
                              _kv('نسبة النمو المتوقعة', _formatPercent(_predictions!['predictedGrowth'])),
                              const SizedBox(height: 8),
                              Text(_predictions!['recommendation']),
                            ],
                          ),
                  ),
                  _buildChartsSection(),
                ],
              ),
            ),
    );
  }

  // توافقًا مع اسم الدالة في المقتطف المرسل
  Future<void> _loadAnalytics() => _load();

  Widget _card({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value'),
        ],
      ),
    );
  }

  String _formatCurrency(Object? v) {
    final num n = (v as num?) ?? 0;
    return '${n.toStringAsFixed(2)} ر.س';
    }

  String _formatPercent(Object? v) {
    final num n = (v as num?) ?? 0;
    return '${n.toStringAsFixed(1)}%';
  }

  

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📈 الرسوم البيانية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // الرسم البياني الخطي
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مسار الإيرادات والربح', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<LineChartData>(
                    future: ChartService.getRevenueChart(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('لا توجد بيانات'));
                      }
                      return LineChart(snapshot.data!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // الرسم البياني الدائري
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('توزيع الربح حسب الفئة', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<PieChartData>(
                    future: ChartService.getCategoryDistributionChart(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('لا توجد بيانات'));
                      }
                      return PieChart(snapshot.data!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

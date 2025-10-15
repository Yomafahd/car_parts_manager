import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/competitor_api_service.dart';
import '../services/competitor_local_store.dart';

class CompetitorsTab extends StatefulWidget {
  const CompetitorsTab({super.key});

  @override
  State<CompetitorsTab> createState() => _CompetitorsTabState();
}

class _CompetitorsTabState extends State<CompetitorsTab> {
  List<Map<String, dynamic>> competitors = [];
  bool _loading = true;
  String? _error;
  Timer? _statusTimer;
  Map<String, dynamic>? _lastStatus;
  Map<String, dynamic>? _results; // { last_run, results: [...], summary: {...} }

  @override
  void initState() {
    super.initState();
    _fetchCompetitors();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'قائمة المنافسين',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: _startScraping,
                  icon: const Icon(Icons.search),
                  label: const Text('بدء المسح'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importArabicList,
                  icon: const Icon(Icons.file_download),
                  label: const Text('استيراد قائمة عربية'),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          if (_lastStatus != null) _buildStatusBanner(_lastStatus!),
          if (_results != null) _buildResultsSummary(_results!),
          if (_results != null) _buildAdvancedResultsPanel(),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: competitors.length,
                itemBuilder: (context, index) {
                  return _buildCompetitorCard(competitors[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic> status) {
    final bool isScraping = status['is_scraping'] == true;
    final int total = (status['total_products'] as int?) ?? 0;
    final String last = (status['last_scraped'] as String?) ?? '-';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isScraping ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isScraping ? Colors.orange : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(isScraping ? Icons.sync : Icons.check_circle,
              color: isScraping ? Colors.orange : Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isScraping
                  ? 'جاري المسح...'
                  : 'آخر مسح: $last • إجمالي المنتجات: $total',
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorCard(Map<String, dynamic> competitor) {
    // Support both API keys and previous local keys for robustness
    final String status = (competitor['status'] ?? '').toString();
    final String website = (competitor['website'] ?? '').toString();
    final int productsCount = (competitor['products_count'] ?? competitor['productsCount'] ?? 0) as int;
    final String lastScraped = (competitor['last_scraped'] ?? competitor['lastScraped'] ?? '-') as String;
    final Color bg = status == 'نشط' ? Colors.green : Colors.orange;
  final String compId = (competitor['id'] ?? competitor['competitor_id'] ?? '').toString();
  final String compName = (competitor['name'] ?? competitor['competitor_name'] ?? 'غير معروف').toString();
  final bool isLocal = (competitor['source'] == 'local');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          competitor['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الموقع: $website'),
            Text('عدد المنتجات: $productsCount'),
            Text('آخر مسح: $lastScraped'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'مسح هذا المنافس',
              icon: const Icon(Icons.search),
              color: Theme.of(context).colorScheme.primary,
              onPressed: isLocal || compId.isEmpty
                  ? null
                  : () => _scrapeIndividualCompetitor(compId, compName),
            ),
            const SizedBox(width: 4),
            Chip(
              label: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: bg,
            ),
          ],
        ),
        onTap: () {
          _showCompetitorDetails(competitor);
        },
      ),
    );
  }

  void _startScraping() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بدء المسح'),
        content: const Text('هل تريد بدء مسح المواقع التنافسية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              nav.pop();
              final ok = await CompetitorApiService.startScraping();
              if (!mounted) return;
              if (ok) {
                _pollStatusWithDialog();
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('تعذر بدء عملية المسح')),
                );
              }
            },
            child: const Text('بدء المسح'),
          ),
        ],
      ),
    );
  }

  Future<void> _scrapeIndividualCompetitor(String competitorId, String competitorName) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await CompetitorApiService.scrapeSingle(competitorId);
      if (!mounted) return;
      if (ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('بدأ مسح $competitorName')),
        );
        _pollStatusOnce();
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('تعذر بدء المسح الفردي')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء بدء المسح')),
      );
    }
  }

  void _pollStatusWithDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('جاري المسح...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري جمع البيانات من المواقع التنافسية...'),
          ],
        ),
      ),
    );

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      try {
        final status = await CompetitorApiService.getScrapingStatus();
        if (!mounted) return;
        setState(() => _lastStatus = status);
        final bool done = status['is_scraping'] != true;
        if (done) {
          t.cancel();
          if (!mounted) return;
          Navigator.of(context).pop();
          _showScrapingResults(status);
          // refresh list after finish
          _fetchCompetitors();
        }
      } catch (_) {
        // ignore intermediate errors
      }
    });
  }

  void _showScrapingResults([Map<String, dynamic>? status]) {
    if (!mounted) return;
    final total = (status?['total_products'] as int?) ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ اكتملت عملية المسح - إجمالي المنتجات: $total'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCompetitorDetails(Map<String, dynamic> competitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(competitor['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الموقع: ${(competitor['website'] ?? '').toString()}'),
            if ((competitor['address'] ?? '').toString().isNotEmpty)
              Text('العنوان: ${(competitor['address'] ?? '').toString()}'),
            if ((competitor['phone'] ?? '').toString().isNotEmpty)
              Text('الهاتف: ${(competitor['phone'] ?? '').toString()}'),
            if ((competitor['location'] ?? '').toString().isNotEmpty)
              Text('الإحداثيات: ${(competitor['location'] ?? '').toString()}'),
            const SizedBox(height: 8),
            Text('عدد المنتجات: ${(competitor['products_count'] ?? competitor['productsCount'] ?? 0)}'),
            const SizedBox(height: 8),
            Text('آخر مسح: ${(competitor['last_scraped'] ?? competitor['lastScraped'] ?? '-') }'),
            const SizedBox(height: 8),
            Text('الحالة: ${competitor['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startCompetitorAnalysis(competitor);
            },
            child: const Text('تحليل المنافس'),
          ),
        ],
      ),
    );
  }

  void _startCompetitorAnalysis(Map<String, dynamic> competitor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔍 جاري تحليل ${competitor['name']}...'),
      ),
    );
  }

  Future<void> _fetchCompetitors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final backendList = await CompetitorApiService.getCompetitors();
      final localList = await CompetitorLocalStore.load();
      final list = [
        ...localList,
        ...backendList,
      ];
      if (!mounted) return;
      setState(() {
        competitors = list;
        _loading = false;
      });
      // also fetch current status
      try {
        final status = await CompetitorApiService.getScrapingStatus();
        final res = await CompetitorApiService.getScrapingResults();
        if (mounted) setState(() { _lastStatus = status; _results = res; });
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر جلب بيانات المنافسين. تأكد من تشغيل الخادم على http://127.0.0.1:5000';
      });
    }
  }

  Future<void> _importArabicList() async {
    final txtCtrl = TextEditingController(text: '[\n  {\n    "الاسم": "شركات قطع غيار محلية",\n    "الموقع": "أسواق محلية في القاهرة",\n    "التخصص": "قطع غيار سيارات متنوعة"\n  }\n]');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد منافسين (JSON بالعربية)'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: txtCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'ألصق هنا مصفوفة JSON تحتوي على مفاتيح عربية: الاسم/الموقع/التخصص',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استيراد')),
        ],
      ),
    );
    if (ok != true) return;
    try {
  final raw = txtCtrl.text.trim();
  final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
      final mapped = arr.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return {
          'name': (m['الاسم'] ?? m['name'] ?? '').toString(),
          'website': (m['الموقع'] ?? m['website'] ?? '').toString(),
          'category': (m['التخصص'] ?? m['category'] ?? '').toString(),
          'phone': (m['الهاتف'] ?? m['phone'] ?? '').toString(),
          'address': (m['العنوان'] ?? m['address'] ?? '').toString(),
          'location': (m['اللوكيشن'] ?? m['الإحداثيات'] ?? m['location'] ?? '').toString(),
          'status': 'نشط',
          'products_count': 0,
          'last_scraped': '-',
          'source': 'local',
        };
      }).where((m) => (m['name'] as String).isNotEmpty).toList();

      await CompetitorLocalStore.addMany(mapped);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد المنافسين بنجاح')));
      _fetchCompetitors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صيغة غير صحيحة لملف JSON')));
    }
  }

  Widget _buildResultsSummary(Map<String, dynamic> res) {
    final summary = (res['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final lastRun = (res['last_run'] as String?) ?? '-';
    final totalCompetitors = (summary['total_competitors'] as int?) ?? 0;
    final totalProducts = (summary['total_products'] as int?) ?? 0;
    final successRate = (summary['success_rate'] as num?)?.toString() ?? '0';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص آخر عملية مسح', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('آخر تشغيل: $lastRun'),
          Text('عدد المنافسين: $totalCompetitors'),
          Text('إجمالي المنتجات: $totalProducts'),
          Text('نسبة النجاح: $successRate%'),
        ],
      ),
    );
  }

  void _pollStatusOnce() async {
    try {
      final status = await CompetitorApiService.getScrapingStatus();
      final res = await CompetitorApiService.getScrapingResults();
      if (!mounted) return;
      setState(() { _lastStatus = status; _results = res; });
    } catch (_) {}
  }

  // إضافة لوحة النتائج المتقدمة
  Widget _buildAdvancedResultsPanel() {
    final scrapingResults = _results;
    if (scrapingResults == null) return const SizedBox.shrink();

    final results = (scrapingResults['results'] as List?) ?? [];
    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس اللوحة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📈 النتائج التفصيلية',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue[800],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('تحديث النتائج'),
                  onPressed: _loadScrapingResults,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // قائمة النتائج التفصيلية
      for (final r in results.reversed.take(5))
        _buildDetailedResultItem((r as Map).cast<String, dynamic>()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedResultItem(Map<String, dynamic> result) {
    final bool isSuccess = result['status'] == 'success';
    final List productsSample = (result['products_sample'] as List?) ?? [];
    final String compName = (result['competitor_name'] ?? result['competitor'] ?? result['name'] ?? 'غير معروف').toString();
    final int productsFound = (result['products_found'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات أساسية
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  compName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  '$productsFound منتج',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: isSuccess ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // رسالة الحالة
          Text(
            (result['message'] ?? 'لا توجد تفاصيل').toString(),
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          // عينات المنتجات (إذا وجدت)
          if (productsSample.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'عينات المنتجات:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            ...productsSample.take(3).map((p) {
              final mp = (p as Map).cast<String, dynamic>();
              final name = (mp['name'] ?? '').toString();
              final price = (mp['price'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_left, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        price.isEmpty ? name : '$name - $price ج.م',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // الطابع الزمني
          if (result['timestamp'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'وقت المسح: ${_formatTimestamp((result['timestamp'] as String?) ?? '')}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
  final dt = DateTime.parse(timestamp).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)} - ${two(dt.day)}/${two(dt.month)}';
    } catch (_) {
      return 'وقت غير معروف';
    }
  }

  Future<void> _loadScrapingResults() async {
    try {
      final res = await CompetitorApiService.getScrapingResults();
      if (!mounted) return;
      setState(() {
        _results = res;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث النتائج')),
      );
    }
  }
}

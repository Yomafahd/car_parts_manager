import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';

class FinancePricingScreen extends StatefulWidget {
  const FinancePricingScreen({super.key});

  @override
  State<FinancePricingScreen> createState() => _FinancePricingScreenState();
}

class _FinancePricingScreenState extends State<FinancePricingScreen> {
  String _policy = 'official';
  Map<String, TextEditingController> _controllers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = AuthService.currentUser;
    if (me == null || (me.role != UserRole.owner && me.role != UserRole.manager)) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final policy = await FinanceService.getCurrentPolicy();
    final rates = await FinanceService.getRates(policy: policy);
    _controllers = {
      for (final c in FinanceService.currencies)
        c: TextEditingController(text: (rates[c] ?? 0).toStringAsFixed(2))
    };
    setState(() {
      _policy = policy;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final Map<String, double> next = {};
    for (final c in FinanceService.currencies) {
      final v = double.tryParse(_controllers[c]?.text.trim() ?? '');
      if (v != null && v > 0) {
        next[c] = v;
      }
    }
    await FinanceService.setRates(next, policy: _policy);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار بنجاح')));
  }

  Future<void> _switchPolicy(String policy) async {
    setState(() => _loading = true);
    await FinanceService.setCurrentPolicy(policy);
    final rates = await FinanceService.getRates(policy: policy);
    for (final c in FinanceService.currencies) {
      _controllers[c]?.text = (rates[c] ?? 0).toStringAsFixed(2);
    }
    setState(() {
      _policy = policy;
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final e in _controllers.values) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;
    if (me == null || (me.role != UserRole.owner && me.role != UserRole.manager)) {
      return const Scaffold(
        body: Center(child: Text('صلاحيات غير كافية')), 
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('التمويل والتسعير — المالك/المدير'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سياسة التسعير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'official', label: Text('السوق الرسمي')),
                      ButtonSegment(value: 'parallel', label: Text('السوق الموازي')),
                    ],
                    selected: {_policy},
                    onSelectionChanged: (s) => _switchPolicy(s.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('أسعار الصرف (إلى الجنيه المصري)'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: FinanceService.currencies.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final code = FinanceService.currencies[index];
                        final ctrl = _controllers[code]!;
                        return ListTile(
                          title: Text(code),
                          subtitle: const Text('قيمة 1 وحدة من العملة بالجنيه المصري'),
                          trailing: SizedBox(
                            width: 120,
                            child: TextField(
                              controller: ctrl,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                labelText: 'سعر الصرف',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          // إعادة تحميل من التخزين
                          setState(() => _loading = true);
                          final rates = await FinanceService.getRates(policy: _policy);
                          for (final c in FinanceService.currencies) {
                            _controllers[c]?.text = (rates[c] ?? 0).toStringAsFixed(2);
                          }
                          setState(() => _loading = false);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('استرجاع'),
                      )
                    ],
                  )
                ],
              ),
            ),
    );
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التمويل والتسعير: تدير أسعار الصرف (رسمي/موازي) وتحوّلات الأسعار إلى الجنيه المصري.
class FinanceService {
  // مفاتيح التخزين المحلية
  static const _kPolicyKey = 'pricing_policy_current'; // 'official' | 'parallel'
  static const _kRatesOfficialKey = 'fx_rates_egp_ar_official';
  static const _kRatesParallelKey = 'fx_rates_egp_ar_parallel';

  // قائمة العملات المدعومة (مفاتيح عربية)
  static const List<String> currencies = [
    'دولار', // USD
    'يورو', // EUR
    'ريال_سعودي', // SAR
    'درهم_إماراتي', // AED
    'دينار_كويتي', // KWD
    'يوان_صيني', // CNY
    'دولار_تايواني', // TWD
  ];

  // القيم الافتراضية (إلى الجنيه المصري) — يمكنك تعديلها من شاشة المالك
  static const Map<String, double> _defaultOfficial = {
    'دولار': 31.0,
    'يورو': 33.0,
    'ريال_سعودي': 8.25,
    'درهم_إماراتي': 8.45,
    'دينار_كويتي': 100.0,
    'يوان_صيني': 4.30,
    'دولار_تايواني': 1.00,
  };

  // افتراضياً: الموازي يبدأ بنفس الرسمي حتى يغيّره المالك
  static const Map<String, double> _defaultParallel = _defaultOfficial;

  // سياسة التسعير الحالية (رسمي/موازي)
  static Future<String> getCurrentPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPolicyKey) ?? 'official';
  }

  static Future<void> setCurrentPolicy(String policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPolicyKey, (policy == 'parallel') ? 'parallel' : 'official');
  }

  // جلب جدول أسعار الصرف لسياسة معينة
  static Future<Map<String, double>> getRates({String? policy}) async {
    final p = policy ?? await getCurrentPolicy();
    final prefs = await SharedPreferences.getInstance();
    final key = (p == 'parallel') ? _kRatesParallelKey : _kRatesOfficialKey;
    final raw = prefs.getString(key);
    if (raw == null) return Map<String, double>.from(p == 'parallel' ? _defaultParallel : _defaultOfficial);
    try {
      final m = (json.decode(raw) as Map).cast<String, dynamic>();
      return m.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return Map<String, double>.from(p == 'parallel' ? _defaultParallel : _defaultOfficial);
    }
  }

  // حفظ جدول أسعار الصرف لسياسة معينة
  static Future<void> setRates(Map<String, double> rates, {String? policy}) async {
    final p = policy ?? await getCurrentPolicy();
    final prefs = await SharedPreferences.getInstance();
    final key = (p == 'parallel') ? _kRatesParallelKey : _kRatesOfficialKey;
    await prefs.setString(key, json.encode(rates));
  }

  // تحديث قيمة عملة واحدة ضمن السياسة المحددة
  static Future<void> setRate(String currencyKey, double rate, {String? policy}) async {
    final rates = await getRates(policy: policy);
    rates[currencyKey] = rate;
    await setRates(rates, policy: policy);
  }

  // تحويل مبلغ من عملة إلى الجنيه المصري بناءً على السياسة الحالية
  static Future<double> toEGP(double amount, String currencyKey, {String? policy}) async {
    final rates = await getRates(policy: policy);
    final rate = rates[currencyKey];
    if (rate == null) return amount; // إذا لم تُعرف العملة، نعيد المبلغ كما هو
    return amount * rate;
  }
}

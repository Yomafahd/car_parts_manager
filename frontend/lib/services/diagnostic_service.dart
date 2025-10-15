import 'dart:math';

import 'inventory_source.dart';

class DiagnosticResult {
  final String summary; // Arabic summary of diagnosis
  final List<String> probableCauses; // bullet points
  final List<Map<String, dynamic>> suggestedParts; // inventory items maps

  DiagnosticResult({
    required this.summary,
    required this.probableCauses,
    required this.suggestedParts,
  });
}

class DiagnosticService {
  // Very simple Arabic keyword rules; can be replaced with LLM later
  static Future<DiagnosticResult> diagnoseFromText(String description) async {
    final text = description.toLowerCase();

    String area = 'عام';
    final causes = <String>[];
    final neededCategories = <String>[];

    if (text.contains('فرامل') || text.contains('تزييق') || text.contains('فرامل')) {
      area = 'نظام الفرامل';
      causes.addAll([
        'تآكل في تيل الفرامل',
        'اعوجاج في الأقراص (هوبات)',
        'نقص في زيت الفرامل أو وجود هواء بالدائرة',
      ]);
      neededCategories.addAll(['أنظمة الفرامل', 'فرامل']);
    } else if (text.contains('بطارية') || text.contains('ما بتدورش') || text.contains('كهرب')) {
      area = 'النظام الكهربي';
      causes.addAll([
        'بطارية ضعيفة أو تالفة',
        'عطل في الدينامو (المولد)',
        'أطراف أو كابلات مرتخية/متأكلة',
      ]);
      neededCategories.addAll(['أنظمة الكهرباء', 'كهرباء']);
    } else if (text.contains('سخونة') || text.contains('حرارة') || text.contains('تبريد')) {
      area = 'نظام التبريد';
      causes.addAll([
        'نقص ماء الردياتير أو تهريب',
        'عطل في مروحة التبريد أو حساس الحرارة',
        'ثرموستات عالق',
      ]);
      neededCategories.addAll(['نظام تبريد', 'ردياتير', 'مراوح']);
    } else if (text.contains('زيت') || text.contains('دخان') || text.contains('صوت محرك')) {
      area = 'المحرك';
      causes.addAll([
        'نقص زيت المحرك أو تسريب',
        'فلتر زيت/هواء مسدود',
        'شمعات إشعال (بواجي) تالفة',
      ]);
      neededCategories.addAll(['زيوت ومواد تشحيم', 'فلاتر هواء ووقود', 'بواجي']);
    } else {
      causes.add('وصف عام؛ نحتاج تفاصيل إضافية لتشخيص أدق');
    }

    final suggestions = await _suggestParts(neededCategories);

    final summary = 'تشخيص مبدئي: $area. يُرجى التأكد من النقاط التالية.';
    return DiagnosticResult(
      summary: summary,
      probableCauses: causes,
      suggestedParts: suggestions,
    );
  }

  static Future<List<Map<String, dynamic>>> _suggestParts(List<String> categories) async {
    if (categories.isEmpty) return [];
    final all = await fetchAllInventoryItems();
    if (all.isEmpty) return [];
    final rand = Random();
    final filtered = all.where((m) {
      final cat = (m['category'] ?? '').toString();
      return categories.any((c) => cat.contains(c));
    }).toList();
    filtered.shuffle(rand);
    return filtered.take(5).toList();
  }
}

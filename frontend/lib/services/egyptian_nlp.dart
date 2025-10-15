import 'dart:async';

/// خدمات بسيطة لمعالجة النصوص باللهجة المصرية (بدون نماذج ثقيلة)
/// الهدف: توفير واجهات يمكن استبدالها لاحقًا بتكاملات مثل AraBERT/ML Kit.
class EgyptianNLP {
  /// محاولة فهم بعض التعابير المصرية الشائعة وتحويلها للفصحى/نوايا بسيطة.
  /// تعيد نصًا "منظَّمًا" ويمكن استخدامه لاحقًا مع محركات بحث أو قواعد أعمال.
  static String understandEgyptianDialect(String text) {
    final normalized = _normalizeArabic(text);
    final mapping = <String, String>{
      'عايز': 'أريد',
      'عاوزه': 'أريد',
      'نفسي': 'أريد',
      'عايزين': 'نريد',
      'فين': 'أين',
      'ازاي': 'كيف',
      'ازاى': 'كيف',
      'ليه': 'لماذا',
      'امتى': 'متى',
      'كام': 'كم',
      'حاجة': 'شيء',
      'حاجه': 'شيء',
      'ده': 'هذا',
      'دى': 'هذه',
      'دي': 'هذه',
      'كده': 'هكذا',
      'كدا': 'هكذا',
      'مش': 'ليس',
      'مافيش': 'لا يوجد',
      'مفيش': 'لا يوجد',
      'تمام': 'حسنًا',
      'اوكي': 'حسنًا',
      'أوكي': 'حسنًا',
      'شوف': 'انظر',
      'بسرعة': 'سريعًا',
      'دلوقتي': 'الآن',
      'النهاردة': 'اليوم',
      'بكره': 'غدًا',
      'مبارح': 'أمس',
      'دلوقت': 'الآن',
    };

    final words = normalized.split(RegExp(r"\s+"));
    final transformed = words.map((w) => mapping[w] ?? w).join(' ');

    // قواعد نية بسيطة (مثال):
    if (RegExp(r'(أريد|نريد) (.*)').hasMatch(transformed)) {
      return 'intent:request -> $transformed';
    }
    if (transformed.contains('أين')) {
      return 'intent:where -> $transformed';
    }
    if (transformed.contains('كيف')) {
      return 'intent:how -> $transformed';
    }
    if (transformed.contains('لماذا')) {
      return 'intent:why -> $transformed';
    }

    return transformed;
  }

  /// محاكاة تحويل الصوت إلى نص (placeholder)
  /// في الإنتاج: اربط بـ Google ML Kit أو واجهة Speech-to-Text تدعم العربية/المصرية.
  static Future<String> speechToTextEgyptian() async {
    // Placeholder قابل للتبديل لاحقًا
    return Future.value('');
  }

  // ===== Helpers =====
  static String _normalizeArabic(String input) {
    var t = input.trim();
    // توحيد الألف والهمزات
    t = t.replaceAll(RegExp('[إأآا]'), 'ا');
    // توحيد الياء/الألف المقصورة
    t = t.replaceAll('ى', 'ي');
    // إزالة التشكيل
    t = t.replaceAll(RegExp('[\u064B-\u0652]'), '');
    // تنعيم المسافات
    t = t.replaceAll(RegExp(' +'), ' ');
    // حروف صغيرة/كبيرة لا تنطبق بالعربية، لكن نضمن توحيدًا آخر إن وجد
    return t;
  }
}

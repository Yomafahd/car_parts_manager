import 'dart:convert';
import 'package:http/http.dart' as http;

/// خدمة فهم اللهجة المصرية مع تكامل اختياري لـ OpenAI
/// ملاحظة مهمة للأمان: لا تضع مفاتيح في الشيفرة. استخدم --dart-define=OPENAI_API_KEY=... عند البناء،
/// أو مرر المفتاح من خادمك. استدعاءات OpenAI من العميل على الويب قد تسرّب المفتاح؛
/// يُفضّل تمرير الطلب عبر خادم وسيط.
class EgyptianNLPService {
  /// يقرأ المفتاح من متغيرات البناء: --dart-define=OPENAI_API_KEY=sk-...
  static String get _apiKey => const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  // قاموس للكلمات المصرية الشائعة -> فصحى مبسطة
  static final Map<String, String> _egyptianDictionary = {
    'ايوه': 'نعم',
    'لأ': 'لا',
    'فعلا': 'حقاً',
    'يا باشا': 'يا صديقي',
    'مش كده': 'أليس كذلك',
    'يعني ايه': 'ماذا يعني',
    'عاوز': 'أريد',
    'عايز': 'أريد',
    'هعمل ايه': 'ماذا أفعل',
    'فين': 'أين',
    'امتى': 'متى',
    'ازاي': 'كيف',
    'كام': 'كم',
    'ماشي': 'حسناً',
    'تمام': 'ممتاز',
    'يا جماعة': 'يا فريق',
    'عظيم': 'رائع',
    'مش عارف': 'لا أعرف',
    'ان شاء الله': 'بإذن الله',
    'ما شاء الله': 'تبارك الله',
    'ربنا يوفقك': 'الله يوفقك',
    'حبيبي': 'عزيزي',
    'باشا': 'صديقي',
    'برنس': 'رائع',
    'مظبوط': 'صحيح',
    'بالظبط': 'تمام',
    'علي طول': 'فوراً',
    'بسرعة': 'سريع',
    'شوية': 'قليلاً',
    'كثير': 'كثير',
    'خالص': 'نهائياً',
    'جدع': 'شهم',
    'مهندس': 'متمكن',
  };

  /// تحويل اللهجة المصرية للفصحى بشكل بدائي عبر استبدال بسيط
  static String translateToModern(String egyptianText) {
    String result = egyptianText;
    _egyptianDictionary.forEach((egyptian, modern) {
      result = result.replaceAll(egyptian, modern);
    });
    return result;
  }

  /// فهم النية بشكل قاعدي (محلي)
  static Map<String, dynamic> understandIntent(String text) {
    final modernText = translateToModern(text.toLowerCase());
    if (modernText.contains('أريد') || modernText.contains('احتياج') || modernText.contains('محتاج')) {
      return {
        'intent': 'need_part',
        'confidence': 0.9,
        'entities': _extractPartInfo(modernText),
        'original': text,
        'modern': modernText,
      };
    } else if (modernText.contains('سعر') || modernText.contains('تكلفة') || modernText.contains('كم')) {
      return {
        'intent': 'price_inquiry',
        'confidence': 0.85,
        'entities': _extractPriceInfo(modernText),
        'original': text,
        'modern': modernText,
      };
    } else if (modernText.contains('أين') || modernText.contains('مكان') || modernText.contains('فروع')) {
      return {
        'intent': 'location_query',
        'confidence': 0.8,
        'entities': <String, dynamic>{},
        'original': text,
        'modern': modernText,
      };
    } else {
      return {
        'intent': 'general_query',
        'confidence': 0.7,
        'entities': <String, dynamic>{},
        'original': text,
        'modern': modernText,
      };
    }
  }

  static Map<String, dynamic> _extractPartInfo(String text) {
    final Map<String, dynamic> entities = {};
    final Map<String, List<String>> partKeywords = {
      'محرك': ['محرك', 'ماتور', 'engine', 'موتور'],
      'فرامل': ['فرامل', 'مكابح', 'brakes', 'كوابح'],
      'بطارية': ['بطارية', 'بطاريه', 'battery', 'كهرباء'],
      'إطارات': ['إطارات', 'كاوتش', 'اطارات', 'tires'],
      'زيت': ['زيت', 'دهان', 'oil', 'شحم'],
    };
    for (final entry in partKeywords.entries) {
      if (entry.value.any((kw) => text.contains(kw))) {
        entities['part_type'] = entry.key;
        break;
      }
    }
    return entities;
  }

  static Map<String, dynamic> _extractPriceInfo(String text) {
    final Map<String, dynamic> entities = {};
    final RegExp digitRegex = RegExp(r'\d+');
    final Match? match = digitRegex.firstMatch(text);
    if (match != null) {
      entities['mentioned_price'] = int.parse(match.group(0)!);
    }
    return entities;
  }

  /// استخدام OpenAI للفهم المتقدم (اختياري). في حال غياب المفتاح، سيتم الرجوع للطريقة المحلية.
  static Future<Map<String, dynamic>> advancedUnderstanding(String text) async {
    if (_apiKey.isEmpty) {
      // مفتاح غير متوفر؛ تجنّب الاستدعاء الشبكي
      return understandIntent(text);
    }
    try {
      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an assistant that understands Egyptian Arabic dialect. Analyze the text and extract: intent, part_type, urgency, and sentiment. Respond in JSON format.'
            },
            {
              'role': 'user',
              'content': 'Text: $text'
            }
          ],
          'max_tokens': 150,
        }),
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content'];
          if (content is String) {
            // حاول قراءة JSON من المحتوى مباشرةً
            try {
              return json.decode(content) as Map<String, dynamic>;
            } catch (_) {
              // محاولة استخراج كائن JSON من داخل النص
              final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
              if (match != null) {
                return json.decode(match.group(0)!) as Map<String, dynamic>;
              }
            }
          }
        }
      }
    } catch (e) {
      // تجاهل الخطأ والرجوع للطريقة المحلية
    }
    return understandIntent(text);
  }
}

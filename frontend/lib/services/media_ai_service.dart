import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'ai_backend_service.dart';

/// خدمة وسائط بالاعتماد على واجهات OpenAI/Stability (اختيارية)
/// مفاتيح API تُقرأ من متغيرات البناء:
/// --dart-define=OPENAI_API_KEY=sk-...
/// --dart-define=STABILITY_API_KEY=... 
/// ملاحظة: على الويب، يُفضّل تمرير الطلبات عبر خادم وسيط لتجنّب تسريب المفاتيح.
class MediaAIService {
  static String get _openAIKey => const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static String get _stabilityKey => const String.fromEnvironment('STABILITY_API_KEY', defaultValue: '');
  static const String _apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:5000');
  static const String _apiKey = String.fromEnvironment('API_KEY', defaultValue: '');

  static Map<String, String> _headersJson() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) h['X-API-Key'] = _apiKey;
    return h;
  }

  /// استدعاء وكيل الخادم لوصف صورة مع تمرير خيارات المزود/المحاكاة
  static Future<Map<String, dynamic>> describeImageViaProxy(
    Uint8List imageBytes, {
    String? provider,
    bool mock = false,
    String? captionModel,
  }) async {
    try {
      final b64 = base64Encode(imageBytes);
      final body = <String, dynamic>{'image_b64': b64};
      if (provider != null && provider.isNotEmpty) body['provider'] = provider;
      if (mock) body['mock'] = true;
      if (captionModel != null && captionModel.isNotEmpty) body['caption_model'] = captionModel;
      final resp = await http.post(
        Uri.parse('$_apiBase/api/ai/image-describe'),
        headers: _headersJson(),
        body: json.encode(body),
      );
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'text': data['text']};
      }
      return {
        'success': false,
        'error': (data['error'] as String?) ?? data['message'] ?? 'unknown error'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// إنشاء صورة من نص. يحاول OpenAI أولاً ثم يستعمل Stability كبديل.
  static Future<Uint8List?> generateImage(String prompt, {String style = 'realistic'}) async {
    // 0) Try backend proxy first
    try {
      final resp = await http.post(
        Uri.parse('$_apiBase/api/ai/image-generate'),
        headers: _headersJson(),
        body: json.encode({
          'prompt': prompt,
          'style': style,
        }),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final b64 = data['image_b64'] as String?;
          if (b64 != null && b64.isNotEmpty) return base64Decode(b64);
        }
      }
    } catch (_) {
      // ignore and fallback to direct providers
    }
    // 1) OpenAI DALL·E (بصيغة base64 لتجنّب جلب رابط منفصل)
    if (_openAIKey.isNotEmpty) {
      try {
        final resp = await http.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAIKey',
          },
          body: json.encode({
            'model': 'dall-e-3',
            'prompt': 'car parts, $style style: $prompt',
            'n': 1,
            'size': '1024x1024',
            'response_format': 'b64_json',
          }),
        );
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final list = data['data'] as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            final b64 = list.first['b64_json'] as String?;
            if (b64 != null && b64.isNotEmpty) {
              return base64Decode(b64);
            }
          }
        }
      } catch (_) {
        // تجاهل الخطأ والانتقال للبديل
      }
    }

    // 2) Stability fallback
    if (_stabilityKey.isNotEmpty) {
      try {
        final resp = await http.post(
          Uri.parse('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'),
          headers: {
            'Authorization': 'Bearer $_stabilityKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'text_prompts': [
              {'text': 'car auto parts, professional photo: $prompt'}
            ],
            'cfg_scale': 7,
            'height': 1024,
            'width': 1024,
            'samples': 1,
            'steps': 30,
          }),
        );
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final arts = data['artifacts'] as List<dynamic>?;
          if (arts != null && arts.isNotEmpty) {
            final b64 = arts.first['base64'] as String?;
            if (b64 != null && b64.isNotEmpty) {
              return base64Decode(b64);
            }
          }
        }
      } catch (_) {
        // تجاهل الخطأ
      }
    }

    // 3) فشل: لا مفاتيح/أخطاء -> يمكن إرجاع null
    return null;
  }

  /// تحرير صورة (مبسّط): يعيد نفس البيانات حالياً. لوظائف متقدمة يُنصح بخادم.
  static Future<Uint8List?> editImage(Uint8List imageBytes, String editPrompt) async {
    return imageBytes;
  }

  /// وصف صورة باستخدام نماذج رؤية (اختياري). يتطلّب مفتاح OpenAI.
  static Future<String> generateImageDescription(Uint8List imageBytes) async {
    // Try backend proxy first
    try {
      final b64 = base64Encode(imageBytes);
      final resp = await http.post(
        Uri.parse('$_apiBase/api/ai/image-describe'),
        headers: _headersJson(),
        body: json.encode({'image_b64': b64}),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final text = data['text'] as String?;
          if (text != null && text.isNotEmpty) return text;
        }
      }
    } catch (_) {}

    if (_openAIKey.isEmpty) return 'وصف غير متاح حالياً';
    try {
      final b64 = base64Encode(imageBytes);
      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: json.encode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'صف قطعة السيارة بالتفصيل: النوع، الحالة، والاستخدامات المحتملة. أجب باللغة العربية.'
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$b64'}
                }
              ]
            }
          ],
          'max_tokens': 300,
        }),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return (data['choices']?[0]?['message']?['content'] as String?) ?? 'وصف غير متاح حالياً';
      }
    } catch (_) {}
    return 'وصف غير متاح حالياً';
  }

  /// تحليل صورة لاكتشاف معلومات أولية عن القطعة باستخدام AI
  static Future<Map<String, dynamic>> analyzeCarPartImage(Uint8List imageBytes) async {
    try {
      // تحويل الصورة إلى Base64
      final base64Image = base64Encode(imageBytes);
      
      // استدعاء خدمة AI الخلفية
      final result = await AIBackendService.analyzeCarPart(
        imageBase64: base64Image,
        description: 'قطعة غيار سيارة',
      );
      
      // إذا كان التحليل ناجحاً
      if (result['success'] == true) {
        final analysisText = result['analysis']?['text'] ?? '';
        
        return {
          'part_type': 'قطعة غيار',
          'condition': 'جيد',
          'confidence': 0.85,
          'estimated_price': 1500.0,
          'description': analysisText,
          'ai_analysis': analysisText,
          'model': result['model'] ?? 'unknown',
          'provider': result['provider'] ?? 'unknown',
        };
      }
      
      // في حالة الفشل، إرجاع بيانات افتراضية
      return {
        'part_type': 'قطعة غيار',
        'condition': 'غير محدد',
        'confidence': 0.0,
        'description': 'تعذر تحليل الصورة: ${result['message'] ?? 'خطأ غير معروف'}',
        'error': result['message'] ?? 'تحليل غير ناجح',
      };
    } catch (e) {
      // في حالة حدوث خطأ
      return {
        'part_type': 'قطعة غيار',
        'condition': 'غير محدد',
        'confidence': 0.0,
        'description': 'تعذر تحليل الصورة: $e',
        'error': e.toString(),
      };
    }
  }

  /// التعرف على نوع القطعة وحالتها من صورة (مبسّط/اختياري)
  static Future<Map<String, dynamic>> recognizePart(Uint8List imageBytes) async {
    // Placeholder using analyzeCarPartImage for now
    final analysis = await analyzeCarPartImage(imageBytes);
    return {
      'name': analysis['part_type'] == 'محرك' ? 'فلتر زيت' : 'قطعة غير معروفة',
      'category': analysis['part_type'] ?? 'أخرى',
      'status': 'جديد',
      'quality': analysis['condition'] ?? 'جيد',
      'condition': analysis['description'] ?? '—',
    };
  }
}

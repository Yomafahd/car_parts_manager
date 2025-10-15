import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

/// خدمة محسنة لفحص حالة مزودي الذكاء عبر خادمنا الوسيط
class AIBackendService {
  // تم تحديث العنوان الافتراضي للمنفذ الجديد
  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // مفتاح API
  static const String _apiKey = String.fromEnvironment(
    'API_KEY', 
    defaultValue: 'car_parts_full_access'
  );

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  static Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) h['X-API-Key'] = _apiKey;
    return h;
  }

  /// يستعلم عن حالة الذكاء الاصطناعي من الخادم مع إعادة المحاولة
  static Future<Map<String, dynamic>> getStatus() async {
    return await _performRequestWithRetry(
      () => http.get(
        Uri.parse('$_apiBase/api/ai/status'), 
        headers: _headers()
      ),
      'getStatus'
    );
  }

  /// تحليل قطعة غيار
  static Future<Map<String, dynamic>> analyzeCarPart({
    required String imageBase64,
    String? description,
  }) async {
    final body = {
      'image_b64': imageBase64,
      if (description != null) 'description': description,
    };

    return await _performRequestWithRetry(
      () => http.post(
        Uri.parse('$_apiBase/api/ai/analyze-car-part'),
        headers: _headers(),
        body: json.encode(body),
      ),
      'analyzeCarPart'
    );
  }

  /// تنفيذ طلب مع إعادة المحاولة ومعالجة الأخطاء
  static Future<Map<String, dynamic>> _performRequestWithRetry(
    Future<http.Response> Function() requestFunction,
    String operationName,
  ) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      attempts++;
      
      try {
        developer.log(
          'محاولة $attempts/$_maxRetries لـ $operationName', 
          name: 'AIBackendService'
        );

        final response = await requestFunction().timeout(_timeout);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          developer.log(
            'نجح $operationName في المحاولة $attempts', 
            name: 'AIBackendService'
          );
          return data;
        } else {
          final errorData = _tryParseJson(response.body);
          final errorMessage = errorData?['message'] ?? 'HTTP ${response.statusCode}';
          
          if (attempts == _maxRetries) {
            return {
              'success': false,
              'error': errorMessage,
              'status_code': response.statusCode,
            };
          }
          
          // انتظار قبل إعادة المحاولة
          await Future.delayed(Duration(seconds: attempts));
        }
        
      } on SocketException catch (e) {
        developer.log(
          'خطأ شبكة في $operationName: $e', 
          name: 'AIBackendService'
        );
        
        if (attempts == _maxRetries) {
          return {
            'success': false,
            'error': 'فشل في الاتصال بالخادم. تأكد من تشغيل الخادم.',
            'details': e.toString(),
          };
        }
        
        await Future.delayed(Duration(seconds: attempts * 2));
        
      } on http.ClientException catch (e) {
        developer.log(
          'خطأ عميل HTTP في $operationName: $e', 
          name: 'AIBackendService'
        );
        
        if (attempts == _maxRetries) {
          return {
            'success': false,
            'error': 'خطأ في الاتصال: ${e.message}',
          };
        }
        
        await Future.delayed(Duration(seconds: attempts));
        
      } catch (e) {
        developer.log(
          'خطأ غير متوقع في $operationName: $e', 
          name: 'AIBackendService'
        );
        
        if (attempts == _maxRetries) {
          return {
            'success': false,
            'error': 'خطأ غير متوقع: $e',
          };
        }
        
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return {
      'success': false,
      'error': 'فشل بعد $_maxRetries محاولات',
    };
  }

  /// محاولة تحليل JSON أو إرجاع null
  static Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

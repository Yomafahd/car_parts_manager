import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// اختبار الاتصال بـ API
Future<void> testApiEndpoint() async {
  const String apiUrl = 'http://127.0.0.1:8000/api/ai/status';
  
  try {
    developer.log('🔄 Testing API connection to: $apiUrl');
    
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      developer.log('✅ API Response: ${json.encode(data)}', name: 'APITest');
    } else {
      developer.log('❌ Failed to connect. Status code: ${response.statusCode}', name: 'APITest');
      developer.log('Response body: ${response.body}', name: 'APITest');
    }
  } on http.ClientException catch (e) {
    developer.log('🔴 Client Exception: $e', name: 'APITest');
  } catch (e) {
    developer.log('❌ Unexpected error: $e', name: 'APITest');
  }
}

void main() async {
  await testApiEndpoint();
}
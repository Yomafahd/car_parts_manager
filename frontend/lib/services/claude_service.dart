import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_keys.dart';

class ClaudeService {
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  
  static Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'x-api-key': ApiKeys.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': message}
        ],
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('خطأ: ${response.statusCode}');
    }
  }
}

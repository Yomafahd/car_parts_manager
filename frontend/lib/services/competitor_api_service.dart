import 'dart:convert';

import 'package:http/http.dart' as http;

class CompetitorApiService {
  // You can override this at build time with --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  // Optional API key header, pass via --dart-define=API_KEY=...
  static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: '');

  static Uri _u(String path) => Uri.parse('$baseUrl$path');

  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getCompetitors() async {
    final res = await http.get(_u('/api/competitors'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load competitors');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['competitors'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  static Future<bool> startScraping() async {
    final res = await http.post(_u('/api/start-scraping'), headers: _headers());
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  static Future<Map<String, dynamic>> getScrapingStatus() async {
    final res = await http.get(_u('/api/scraping-status'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to get status');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['status'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> getScrapingResults() async {
    final res = await http.get(_u('/api/scraping-results'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to get results');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['results'] as Map).cast<String, dynamic>();
  }

  static Future<bool> scrapeSingle(String competitorId) async {
    final res = await http.post(_u('/api/competitor/$competitorId/scrape'), headers: _headers());
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['success'] == true;
  }
}

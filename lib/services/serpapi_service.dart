import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SerpApiService {
  static const String _baseUrl = 'https://serpapi.com/search.json';
  static String get _apiKey => dotenv.get('SERPAPI_KEY', fallback: '');

  Future<List<Map<String, dynamic>>> searchNearby(String query, double lat, double lon) async {
    final key = _apiKey;
    if (key.isEmpty || key == 'YOUR_REAL_SERPAPI_KEY_HERE') {
      print('SerpApi Error: API Key not configured');
      return [];
    }

    try {
      final url = Uri.parse('$_baseUrl?engine=google_maps&q=$query&ll=@$lat,$lon,14z&api_key=$key');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['local_results'] ?? [];
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('SerpApi Error: $e');
    }
    return [];
  }
}

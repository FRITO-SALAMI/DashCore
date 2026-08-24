import 'dart:convert';
import 'package:http/http.dart' as http;

class SerpApiService {
  static const String _baseUrl = 'https://serpapi.com/search.json';
  static const String _apiKey = 'YOUR_SERPAPI_KEY_HERE'; // User needs to provide this

  Future<List<Map<String, dynamic>>> searchNearby(String query, double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl?engine=google_maps&q=$query&ll=@$lat,$lon,14z&api_key=$_apiKey');
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

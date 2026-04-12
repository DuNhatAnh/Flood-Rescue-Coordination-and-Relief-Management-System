import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<Map<String, double>?> searchAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {
          'Accept-Language': 'vi', // Ưu tiên tên tiếng Việt
          'User-Agent': 'FloodRescueApp/1.0', // Yêu cầu của Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final first = data[0];
          return {
            'lat': double.parse(first['lat']),
            'lng': double.parse(first['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }
}

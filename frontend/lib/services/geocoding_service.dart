import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<Map<String, double>?> searchAddress(String address) async {
    List<String> parts = address.split(',').map((e) => e.trim()).toList();
    
    // Thử tìm địa chỉ đầy đủ trước, sau đó rút gọn dần từ trái sang phải
    // Ví dụ: "Gầm cầu Đỏ, đường Thăng Long, Đà Nẵng" -> "đường Thăng Long, Đà Nẵng"
    for (int i = 0; i < parts.length; i++) {
      String currentQuery = parts.sublist(i).join(', ');
      if (currentQuery.isEmpty) continue;

      try {
        final response = await http.get(
          Uri.parse('$_baseUrl?q=${Uri.encodeComponent(currentQuery)}&format=json&limit=1'),
          headers: {
            'Accept-Language': 'vi',
            'User-Agent': 'FloodRescueApp/1.0',
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
        
        // Nếu đã thử đến phần tỉnh/thành phố mà vẫn không ra thì dừng (tránh kết quả quá rộng)
        if (parts.length - i <= 1) break; 
        
      } catch (e) {
        print('Geocoding error at try $i: $e');
      }
      
      // Nghỉ một chút giữa các lần request để tránh bị giới hạn (Nominatim policy)
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }
}

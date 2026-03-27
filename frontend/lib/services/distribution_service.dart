import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/distribution.dart';
import 'auth_service.dart';

class DistributionService {
  static const String baseUrl = 'http://localhost:8080/api/distributions';

  Future<bool> createDistribution(String warehouseId, String? requestId, List<Map<String, dynamic>> items, {String type = "EXPORT", String? destinationWarehouseId}) async {
    try {
      final token = await AuthService.getToken();
      final body = {
        'warehouseId': warehouseId,
        'requestId': requestId,
        'type': type,
        'destinationWarehouseId': destinationWarehouseId,
        'items': items,
      };
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Distribution>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Distribution.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

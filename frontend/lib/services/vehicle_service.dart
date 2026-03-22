import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  final String baseUrl = 'http://localhost:8080/api/v1';

  Future<Map<String, dynamic>> getAllVehicles({int page = 0, int size = 10, String? type, String? status}) async {
    String url = '$baseUrl/vehicles?page=$page&size=$size';
    if (type != null && type.isNotEmpty) url += '&type=$type';
    if (status != null && status.isNotEmpty) url += '&status=$status';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Backend returns a Page<VehicleResponse>, which usually has 'content' array and 'pageable' etc.
      // Or if it's wrapped in ApiResponse, it will be body['data']['content']? 
      // Let's assume the controller returns ResponseEntity.ok(vehiclesService.getAllVehicles)
      // which means it returns the Page object directly.
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load vehicles');
  }

  Future<List<dynamic>> getAvailableVehicles() async {
    final response = await http.get(Uri.parse('$baseUrl/vehicles/available'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load available vehicles');
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vehicles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create vehicle');
  }

  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vehicles/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update vehicle');
  }

  Future<void> deleteVehicle(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/vehicles/$id'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete vehicle');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class VehicleService {
  final String baseUrl = Constants.apiV1;

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. Lấy danh sách tất cả phương tiện (Phân trang và Lọc)
  Future<Map<String, dynamic>> getAllVehicles({
    int page = 0, 
    int size = 10, 
    String? type, 
    String? status,
    String? warehouseId,
  }) async {
    String url = '$baseUrl/vehicles?page=$page&size=$size';
    if (type != null && type.isNotEmpty) url += '&type=$type';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    if (warehouseId != null && warehouseId.isNotEmpty) url += '&warehouseId=$warehouseId';

    try {
      final response = await http.get(Uri.parse(url), headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception('Không thể tải danh sách phương tiện (Code: ${response.statusCode})');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// 2. Lấy danh sách phương tiện đang rảnh (Available)
  Future<List<dynamic>> getAvailableVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/available'), headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return (body is Map && body['success'] == true) ? body['data'] : (body as List);
      }
      throw Exception('Không thể tải danh sách xe sẵn sàng');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// 3. Tạo mới một phương tiện
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles?userId=$userId'),
        headers: await _headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception('Lỗi tạo phương tiện: ${response.body}');
    } catch (e) {
      throw Exception('Lỗi kết nối khi tạo: $e');
    }
  }

  /// 4. Cập nhật thông tin phương tiện
  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$id?userId=$userId'),
        headers: await _headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception('Lỗi cập nhật phương tiện: ${response.body}');
    } catch (e) {
      throw Exception('Lỗi kết nối khi cập nhật: $e');
    }
  }

  /// 5. Xóa phương tiện
  Future<void> deleteVehicle(String id, {required String userId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$id?userId=$userId'),
        headers: await _headers()
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Lỗi khi xóa phương tiện (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi xóa: $e');
    }
  }
}
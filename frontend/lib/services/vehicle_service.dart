import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class VehicleService {
  final String baseUrl = Constants.apiV1;

  // Hàm hỗ trợ tạo Header với Token bảo mật
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. Lấy danh sách tất cả phương tiện (Hỗ trợ phân trang và lọc)
  Future<Map<String, dynamic>> getAllVehicles({
    int page = 0, 
    int size = 10, 
    String? type, 
    String? status,
    String? warehouseId,
  }) async {
    // Xây dựng Query Parameters
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (warehouseId != null && warehouseId.isNotEmpty) 'warehouseId': warehouseId,
    };

    final uri = Uri.parse('$baseUrl/vehicles').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: await _headers());
      
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        // Trả về data bên trong nếu thành công, nếu không trả về toàn bộ body
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception('Lỗi hệ thống (${response.statusCode}): Không thể tải danh sách.');
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  /// 2. Lấy số liệu thống kê cho biểu đồ (Tổng cộng, Rảnh, Bận, Bảo trì)
  Future<Map<String, dynamic>> getVehicleStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/statistics-summary'), 
        headers: await _headers()
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (body is Map && body['success'] == true && body['data'] != null) {
          return body['data'];
        }
      }
      // Trả về dữ liệu trống mặc định để tránh lỗi giao diện
      return {'total': 0, 'available': 0, 'in_use': 0, 'maintenance': 0};
    } catch (e) {
      print('VehicleService Error (getVehicleStatistics): $e');
      return {'total': 0, 'available': 0, 'in_use': 0, 'maintenance': 0};
    }
  }

  /// 3. Lấy danh sách phương tiện đang sẵn sàng (Available)
  Future<List<dynamic>> getAvailableVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/available'), 
        headers: await _headers()
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) return body['data'];
        return body as List;
      }
      throw Exception('Không thể tải danh sách xe sẵn sàng.');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// 4. Tạo mới một phương tiện
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles?userId=$userId'),
        headers: await _headers(),
        body: jsonEncode(data),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception(body['message'] ?? 'Lỗi khi tạo phương tiện');
    } catch (e) {
      throw Exception('Lỗi tạo mới: $e');
    }
  }

  /// 5. Cập nhật thông tin phương tiện
  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$id?userId=$userId'),
        headers: await _headers(),
        body: jsonEncode(data),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception(body['message'] ?? 'Lỗi khi cập nhật phương tiện');
    } catch (e) {
      throw Exception('Lỗi cập nhật: $e');
    }
  }

  /// 6. Xóa phương tiện
  Future<void> deleteVehicle(String id, {required String userId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$id?userId=$userId'),
        headers: await _headers()
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['message'] ?? 'Không thể xóa phương tiện');
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa: $e');
    }
  }
}
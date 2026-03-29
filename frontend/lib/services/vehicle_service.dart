import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  // Lưu ý: Đổi 'localhost' thành '10.0.2.2' nếu bạn chạy trên Emulator Android
  final String baseUrl = 'http://localhost:8080/api/v1';

  /// 1. Lấy danh sách tất cả phương tiện (Phân trang và Lọc)
  /// Trả về đối tượng Map chứa thông tin Page (content, totalPages, totalElements...)
  Future<Map<String, dynamic>> getAllVehicles({
    int page = 0, 
    int size = 10, 
    String? type, 
    String? status
  }) async {
    // Xây dựng Query Parameters
    String url = '$baseUrl/vehicles?page=$page&size=$size';
    if (type != null && type.isNotEmpty) url += '&type=$type';
    if (status != null && status.isNotEmpty) url += '&status=$status';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return body['data'];
        }
        return body;
      } else {
        throw Exception('Không thể tải danh sách phương tiện (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// 2. Lấy danh sách phương tiện đang rảnh (Available)
  Future<List<dynamic>> getAvailableVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/available'));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return body['data'] as List<dynamic>;
        }
        return body as List<dynamic>;
      } else {
        throw Exception('Không thể tải danh sách xe sẵn sàng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// 3. Tạo mới một phương tiện
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data, {String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles?userId=${userId ?? ''}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
        return body as Map<String, dynamic>;
      } else {
        throw Exception('Lỗi tạo phương tiện: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi tạo: $e');
    }
  }

  /// 4. Cập nhật thông tin phương tiện
  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data, {String? userId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$id?userId=${userId ?? ''}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
        return body as Map<String, dynamic>;
      } else {
        throw Exception('Lỗi cập nhật phương tiện: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi cập nhật: $e');
    }
  }

  /// 5. Xóa phương tiện
  Future<void> deleteVehicle(String id, {String? userId}) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/vehicles/$id?userId=${userId ?? ''}'));

      // Backend trả về ResponseEntity.noContent() tương ứng 204
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Lỗi khi xóa phương tiện (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi xóa: $e');
    }
  }
}
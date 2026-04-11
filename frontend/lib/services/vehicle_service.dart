import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class VehicleService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Constants.apiV1,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Hàm khởi tạo để cấu hình Interceptor cho JWT Token
  VehicleService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// 1. Lấy danh sách tất cả phương tiện (Hỗ trợ phân trang và lọc)
  Future<Map<String, dynamic>> getAllVehicles({
    int page = 0, 
    int size = 10, 
    String? type, 
    String? status,
    String? warehouseId,
  }) async {
    try {
      final response = await _dio.get('/vehicles', queryParameters: {
        'page': page,
        'size': size,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        if (warehouseId != null && warehouseId.isNotEmpty) 'warehouseId': warehouseId,
      });

      if (response.statusCode == 200) {
        final body = response.data;
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception('Lỗi hệ thống (${response.statusCode}): Không thể tải danh sách.');
    } catch (e) {
      _handleError('getAllVehicles', e);
      rethrow;
    }
  }

  /// 2. Lấy số liệu thống kê cho biểu đồ (Tổng cộng, Rảnh, Bận, Bảo trì)
  Future<Map<String, dynamic>> getVehicleStatistics() async {
    try {
      final response = await _dio.get('/vehicles/statistics-summary');

      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['success'] == true && body['data'] != null) {
          return body['data'];
        }
      }
      return {'total': 0, 'available': 0, 'in_use': 0, 'maintenance': 0};
    } catch (e) {
      print('VehicleService Error (getVehicleStatistics): $e');
      return {'total': 0, 'available': 0, 'in_use': 0, 'maintenance': 0};
    }
  }

  /// 3. Lấy danh sách phương tiện đang sẵn sàng (Available)
  Future<List<dynamic>> getAvailableVehicles() async {
    try {
      final response = await _dio.get('/vehicles/available');

      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['success'] == true) return body['data'];
        return body as List;
      }
      throw Exception('Không thể tải danh sách xe sẵn sàng.');
    } catch (e) {
      _handleError('getAvailableVehicles', e);
      rethrow;
    }
  }

  /// 4. Tạo mới một phương tiện
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await _dio.post(
        '/vehicles',
        queryParameters: {'userId': userId},
        data: data,
      );

      final body = response.data;
      if (response.statusCode == 201 || response.statusCode == 200) {
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception(body['message'] ?? 'Lỗi khi tạo phương tiện');
    } catch (e) {
      _handleError('createVehicle', e);
      rethrow;
    }
  }

  /// 5. Cập nhật thông tin phương tiện
  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data, {required String userId}) async {
    try {
      final response = await _dio.put(
        '/vehicles/$id',
        queryParameters: {'userId': userId},
        data: data,
      );

      final body = response.data;
      if (response.statusCode == 200) {
        return (body is Map && body['success'] == true) ? body['data'] : body;
      }
      throw Exception(body['message'] ?? 'Lỗi khi cập nhật phương tiện');
    } catch (e) {
      _handleError('updateVehicle', e);
      rethrow;
    }
  }

  /// 6. Xóa phương tiện
  Future<void> deleteVehicle(String id, {required String userId}) async {
    try {
      final response = await _dio.delete(
        '/vehicles/$id',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final body = response.data;
        throw Exception(body['message'] ?? 'Không thể xóa phương tiện');
      }
    } catch (e) {
      _handleError('deleteVehicle', e);
      rethrow;
    }
  }

  // Hàm hỗ trợ log lỗi tập trung
  void _handleError(String method, dynamic e) {
    if (e is DioException) {
      print('VehicleService Error ($method): ${e.response?.statusCode} - ${e.message}');
    } else {
      print('VehicleService Error ($method): $e');
    }
  }
}
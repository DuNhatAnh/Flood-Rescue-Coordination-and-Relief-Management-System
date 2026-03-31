import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/distribution.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class DistributionService {
  // Đảm bảo baseUrl trỏ đúng đến API Spring Boot của bạn (không có /v1)
  // Nếu Constants.apiBaseUrl của bạn đang có /v1, hãy dùng .replaceAll('/v1', '')
  final String baseUrl = "http://localhost:8080/api/distributions";

  /// Lấy Header có chứa Token để xác thực
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Tạo mới một lệnh phân phối/xuất kho
  Future<bool> createDistribution(
    String warehouseId, 
    String? requestId, 
    List<Map<String, dynamic>> items, 
    {String type = "EXPORT", String? destinationWarehouseId}
  ) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'warehouseId': warehouseId,
        'requestId': requestId,
        'type': type,
        'destinationWarehouseId': destinationWarehouseId,
        'items': items,
      };
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) print("🚀 Create Status: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print("⚠️ Lỗi createDistribution: $e");
      return false;
    }
  }

  /// Lấy danh sách lịch sử biến động nguồn lực
  Future<List<Distribution>> getHistory() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/history'); 

      if (kDebugMode) print("🌐 Đang gọi API: $url");

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Postman cho thấy bạn nhận về một mảng [ {...}, {...} ] trực tiếp
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        
        List<dynamic> listData = [];
        
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          listData = decodedData['data'] as List<dynamic>;
        }

        if (kDebugMode) print("✅ Đã nhận ${listData.length} mục lịch sử từ Server");
        
        return listData.map((item) => Distribution.fromJson(item)).toList();
      } else {
        if (kDebugMode) print("❌ Lỗi API (${response.statusCode}): ${response.body}");
        return [];
      }
    } on SocketException {
      if (kDebugMode) print("🌐 Lỗi kết nối: Hãy kiểm tra Server Spring Boot đang chạy");
      return [];
    } catch (e) {
      if (kDebugMode) print("⚠️ Lỗi mapping dữ liệu: $e");
      return [];
    }
  }
}
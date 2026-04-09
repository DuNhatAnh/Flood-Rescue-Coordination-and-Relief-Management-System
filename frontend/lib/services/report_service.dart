import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/dashboard_stats_model.dart'; // Đảm bảo import đúng model đã tạo
import 'auth_service.dart';

class ReportService {
  final String baseUrl = "${Constants.apiV1}/reports";

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', 
    };
  }

  /// Lấy dữ liệu Dashboard cho nhân viên
  /// Đã cập nhật trả về DashboardStats? thay vì Map
  Future<DashboardStats?> getStaffDashboard() async {
    try {
      final url = Uri.parse('$baseUrl/staff-dashboard');
      final headers = await _getHeaders();
      
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 15), // Tăng timeout để xử lý các báo cáo phức tạp
      );

      if (kDebugMode) {
        print("🚀 [GET] Staff Dashboard (${response.statusCode})");
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Kiểm tra success và data từ cấu trúc ApiResponse của Spring Boot
        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
          // Chuyển đổi Map thành Object DashboardStats thông qua factory fromJson
          return DashboardStats.fromJson(decodedResponse['data']);
        }
      } else if (response.statusCode == 401) {
        if (kDebugMode) print("🔑 Phiên đăng nhập hết hạn (401)");
      }
      return null; 
    } catch (e) {
      if (kDebugMode) print("⚠️ Lỗi kết nối ReportService: $e");
      return null;
    }
  }

  /// Lấy thống kê chung (Admin)
  Future<Map<String, dynamic>?> getGeneralStats() async {
    try {
      final url = Uri.parse('$baseUrl/general-stats');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
          return decodedResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("⚠️ Lỗi GeneralStats: $e");
      return null;
    }
  }
}
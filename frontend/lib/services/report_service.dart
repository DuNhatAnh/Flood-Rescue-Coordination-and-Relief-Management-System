import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ReportService {
  final String baseUrl = "${Constants.apiBaseUrl}/reports";

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', 
    };
  }

  /// Lấy dữ liệu Dashboard cho nhân viên
  Future<Map<String, dynamic>?> getStaffDashboard() async {
    try {
      final url = Uri.parse('$baseUrl/staff-dashboard');
      final headers = await _getHeaders();
      
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (kDebugMode) print("🚀 Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        // CHUẨN HÓA: Chỉ trả về nội dung của key 'data'
        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
          return decodedResponse['data'] as Map<String, dynamic>;
        }
        return null; 
      } else if (response.statusCode == 401) {
        if (kDebugMode) print("🔑 Token expired hoặc không hợp lệ");
        // Có thể thêm logic logout hoặc refresh token ở đây
        return null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("⚠️ Lỗi ReportService: $e");
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
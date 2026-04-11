import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final String baseUrl = "${Constants.apiV1}/notifications";

  // Header chung cho các request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // 0. Lấy TẤT CẢ thông báo (Dùng cho Admin/Coordinator)
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        if (body['data'] != null) {
          List<dynamic> data = body['data']; 
          return data.map((item) => NotificationModel.fromJson(item)).toList();
        }
        return [];
      }
      throw Exception("Server trả về lỗi: ${response.statusCode}");
    } catch (e) {
      debugPrint("Chi tiết lỗi getAllNotifications: $e");
      throw Exception("Không thể kết nối máy chủ.");
    }
  }

  // 1. Lấy tất cả thông báo của 1 User
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/user/$userId"), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        if (body['data'] != null) {
          List<dynamic> data = body['data']; 
          return data.map((item) => NotificationModel.fromJson(item)).toList();
        }
        return [];
      }
      throw Exception("Server trả về lỗi: ${response.statusCode}");
    } catch (e) {
      debugPrint("Chi tiết lỗi getUserNotifications: $e");
      throw Exception("Không thể kết nối máy chủ.");
    }
  }

  // 2. Lấy số lượng thông báo CHƯA ĐỌC
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/unread-count?userId=$userId"),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return (body['data'] as num).toInt(); // Dùng num để an toàn hơn với kiểu int/double
      }
      return 0;
    } catch (e) {
      debugPrint("Lỗi getUnreadCount: $e");
      return 0;
    }
  }

  // 3. Đánh dấu đã đọc
  Future<void> markAsRead(String id) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/$id/read"),
        headers: _headers,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Cập nhật thất bại: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi markAsRead: $e");
      rethrow; // Ném lỗi để UI (NotificationScreen) có thể catch và hiện SnackBar
    }
  }

  // 4. Xóa tất cả thông báo
  Future<void> deleteAll(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/user/$userId"),
        headers: _headers,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Xóa thất bại: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi deleteAll: $e");
      rethrow;
    }
  }
}
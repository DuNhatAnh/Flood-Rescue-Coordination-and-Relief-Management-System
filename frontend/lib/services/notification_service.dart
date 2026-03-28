import 'dart:convert';
import 'dart:io'; // Thêm để kiểm tra nền tảng
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  // Tự động điều chỉnh IP tùy theo môi trường chạy
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:8080/api/v1/notifications";
    // Nếu là Android Emulator thì dùng 10.0.2.2, nếu iOS/Thật thì dùng IP máy tính
    return Platform.isAndroid 
        ? "http://10.0.2.2:8080/api/v1/notifications" 
        : "http://localhost:8080/api/v1/notifications";
  }

  // Header chung cho các request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // 1. Lấy tất cả thông báo
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: _headers)
          .timeout(const Duration(seconds: 10)); // Tránh treo app nếu server chết

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        
        // Kiểm tra xem trường 'data' có tồn tại không
        if (body['data'] != null) {
          List<dynamic> data = body['data']; 
          return data.map((item) => NotificationModel.fromJson(item)).toList();
        }
        return [];
      }
      throw Exception("Server trả về lỗi: ${response.statusCode}");
    } catch (e) {
      debugPrint("Chi tiết lỗi getAllNotifications: $e");
      throw Exception("Không thể kết nối máy chủ. Vui lòng kiểm tra lại mạng hoặc Backend.");
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
      final response = await http.put(
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
}
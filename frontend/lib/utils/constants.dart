import 'package:flutter/foundation.dart';

class Constants {
  // 1. Base URL - Tự động nhận diện môi trường chạy
  static String get _host {
    if (kIsWeb) {
      return "http://localhost:8080";
    }
    // Đối với giả lập Android, sử dụng 10.0.2.2
    return "http://10.0.2.2:8080";
    
    // Nếu dùng máy thật, bạn nên dùng IP nội bộ, VD:
    // return "http://192.168.1.5:8080";
  }

  static String get apiBaseUrl => "$_host/api";
  static String get apiV1 => "$_host/api/v1";
  static String get apiAuth => "$_host/api/auth";

  // 2. Các thông báo mặc định
  static const String connectionError = "Lỗi kết nối Server, vui lòng kiểm tra lại!";
  static const String sessionExpired = "Phiên đăng nhập đã hết hạn.";

  // 3. Các hằng số về giao diện
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
}
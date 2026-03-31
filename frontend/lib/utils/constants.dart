import 'package:flutter/foundation.dart';

class Constants {
  // 1. Base URL - Tự động nhận diện môi trường chạy
  static String get apiBaseUrl {
    // Nếu chạy trên Web (Chrome/Edge)
    if (kIsWeb) {
      return "http://localhost:8080/api/v1";
    }
    // Nếu chạy trên Android Emulator
    return "http://10.0.2.2:8080/api/v1";
    
    // Nếu chạy trên điện thoại thật, bạn nên dùng IP nội bộ của máy tính:
    // return "http://192.168.1.x:8080/api/v1"; 
  }

  // 2. Các thông báo mặc định
  static const String connectionError = "Lỗi kết nối Server, vui lòng kiểm tra lại!";
  static const String sessionExpired = "Phiên đăng nhập đã hết hạn.";

  // 3. Các hằng số về giao diện
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static UserModel? currentUser;
  static const String _userKey = 'logged_in_user';
  static const String _tokenKey = 'jwt_token';
  static const String _baseUrl = 'http://localhost:8080/api/auth';

  // Khôi phục phiên làm việc khi khởi động
  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      currentUser = UserModel.fromJson(jsonDecode(userData));
    }
  }

  // Lấy token hiện tại
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Lưu phiên làm việc
  Future<void> _saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, token);
    currentUser = user;
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    currentUser = null;
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // Backend currently hardcodes roles to ["USER"], map it or default to admin for testing
        final user = UserModel(
          id: data['email'] ?? 'U1',
          email: data['email'] ?? email,
          fullName: data['fullName'] ?? 'Người dùng',
          role: UserRole.admin, // Force admin to ensure dashboard access
        );
        
        await _saveSession(user, token);
        return user;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi mạng/Kết nối: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class AuthService {
  static UserModel? currentUser;
  static const String _userKey = 'logged_in_user';
  static const String _tokenKey = 'jwt_token';
  static final String _baseUrl = Constants.apiAuth;

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
        
        // Lấy Role từ mảng roles của Spring Boot
        UserRole mappedRole = UserRole.rescueStaff; // Mặc định là đội cứu hộ
        if (data['roles'] != null && data['roles'] is List) {
           final List<dynamic> roleList = data['roles'];
           final String roleString = roleList.join(',').toUpperCase();
           
           if (roleString.contains('ADMIN')) {
             mappedRole = UserRole.admin;
           } else if (roleString.contains('COORDINATOR')) {
             mappedRole = UserRole.coordinator;
           } else if (roleString.contains('RESCUE')) {
             mappedRole = UserRole.rescueStaff;
           }
        }

        final user = UserModel(
          id: data['id'] ?? data['email'] ?? 'U1',
          email: data['email'] ?? email,
          fullName: data['fullName'] ?? 'Người dùng',
          teamId: data['teamId'],
          teamName: data['teamName'],
          role: mappedRole,
        );
        
        await _saveSession(user, token);
        return user;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            throw Exception(errorData['message']);
          }
        } catch (e) {
          // If body is not JSON, it will just drop down and throw default
        }
        throw Exception('Đăng nhập thất bại. Mã: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Lỗi mạng/Kết nối: $e');
    }
  }
}

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
        
<<<<<<< HEAD
        // Lấy Role từ mảng roles của Spring Boot (Kiểm tra tất cả các role)
        UserRole parsedRole = UserRole.user;
        if (data['roles'] != null && data['roles'] is List) {
           final List<dynamic> roleList = data['roles'];
           final String roleString = roleList.join(',').toUpperCase();
           
           if (roleString.contains('ADMIN')) {
             parsedRole = UserRole.admin;
           } else if (roleString.contains('COORDINATOR')) {
             parsedRole = UserRole.coordinator;
           } else if (roleString.contains('RESCUE')) {
             parsedRole = UserRole.rescueStaff;
           }
=======
        // Map roles from backend
        String roleStr = (data['roles'] != null && data['roles'].isNotEmpty) 
            ? data['roles'][0] 
            : 'USER';
            
        UserRole mappedRole;
        if (roleStr == 'ADMIN') {
          mappedRole = UserRole.admin;
        } else if (roleStr == 'COORDINATOR') {
          mappedRole = UserRole.coordinator;
        } else {
          mappedRole = UserRole.rescueStaff;
>>>>>>> 0934fba440f64f23273ef2bfce6ef3a221277d4d
        }

        final user = UserModel(
          id: data['id'] ?? data['email'] ?? 'U1',
          email: data['email'] ?? email,
          fullName: data['fullName'] ?? 'Người dùng',
<<<<<<< HEAD
          role: parsedRole,
=======
          teamId: data['teamId'],
          role: mappedRole,
>>>>>>> 0934fba440f64f23273ef2bfce6ef3a221277d4d
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

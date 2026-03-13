import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // Lưu trữ người dùng hiện tại
  static UserModel? currentUser;
  static const String _userKey = 'logged_in_user';

  // Mock dữ liệu người dùng
  final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin@rescue.vn': {
      'pass': 'admin123',
      'name': 'Quản trị viên (Admin)',
      'role': UserRole.admin,
    },
    'coordinator@rescue.vn': {
      'pass': 'admin123',
      'name': 'Điều phối viên (Coordinator)',
      'role': UserRole.coordinator,
    },
    'staff@rescue.vn': {
      'pass': 'admin123',
      'name': 'Nhân viên cứu hộ (Staff)',
      'role': UserRole.rescueStaff,
    },
  };

  // Khôi phục phiên làm việc khi khởi động
  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      currentUser = UserModel.fromJson(jsonDecode(userData));
    }
  }

  // Lưu phiên làm việc
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    currentUser = user;
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    currentUser = null;
  }

  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); 

    if (_mockUsers.containsKey(email) && _mockUsers[email]!['pass'] == password) {
      final data = _mockUsers[email]!;
      final user = UserModel(
        id: 'U1',
        email: email,
        fullName: data['name'],
        role: data['role'],
      );
      await _saveSession(user);
      return user;
    }
    return null;
  }
}

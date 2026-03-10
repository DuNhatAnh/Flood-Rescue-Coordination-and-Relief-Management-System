import '../models/user_model.dart';

class AuthService {
  // Lưu trữ người dùng hiện tại
  static UserModel? currentUser;

  // Mock dữ liệu người dùng như yêu cầu của bạn
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

  Future<UserModel?> login(String email, String password) async {
    // Giả lập độ trễ mạng để tăng cảm giác thực tế
    await Future.delayed(const Duration(milliseconds: 800)); 

    if (_mockUsers.containsKey(email) && _mockUsers[email]!['pass'] == password) {
      final data = _mockUsers[email]!;
      return UserModel(
        id: 'U1',
        email: email,
        fullName: data['name'],
        role: data['role'],
      );
    }
    return null;
  }
}

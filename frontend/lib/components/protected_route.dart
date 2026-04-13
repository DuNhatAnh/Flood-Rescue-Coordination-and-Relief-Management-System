import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/home_screen.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;

  const ProtectedRoute({
    Key? key,
    required this.child,
    required this.allowedRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    // 1. Kiểm tra đăng nhập
    if (user == null) {
      // Chạy sau khi build xong để tránh lỗi setState/Navigator trong build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để tiếp tục'),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Kiểm tra quyền (Role)
    if (!allowedRoles.contains(user.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền truy cập khu vực này'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../coordinator/coordinator_dashboard.dart';
import '../rescue_team/team_tasks_screen.dart';
import '../rescue_team/staff_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    if (AuthService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDashboard(AuthService.currentUser!);
      });
    }
  }

  void _navigateToDashboard(UserModel user) {
    Widget nextScreen;
    switch (user.role) {
      case UserRole.admin:
        nextScreen = Scaffold(
          appBar: AppBar(title: const Text('Admin Panel')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chào mừng Admin!',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService.logout();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (c) => const LoginScreen()));
                    }
                  },
                  child: const Text('Đăng xuất'),
                )
              ],
            ),
          ),
        );
        break;
      case UserRole.coordinator:
        nextScreen = const CoordinatorDashboard();
        break;
      case UserRole.rescueStaff:
        nextScreen = const StaffMainScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final user = await _authService.login(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // Lưu trạng thái đăng nhập
        AuthService.currentUser = user;

        // Logic chuyển hướng quan trọng dựa trên Vai trò (Role)
        _navigateToDashboard(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email hoặc mật khẩu không chính xác!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Có lỗi xảy ra, vui lòng thử lại!'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF01579B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flood_outlined, size: 100, color: Color(0xFF0288D1)),
              const SizedBox(height: 20),
              const Text(
                'Flood Rescue System',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
              ),
              const Text('Hệ thống Quản lý Cứu hộ Lũ lụt', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email người dùng',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Dùng tài khoản được cấp để truy cập hệ thống', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

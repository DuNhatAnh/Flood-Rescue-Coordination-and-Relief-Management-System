import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.restoreSession();
  runApp(const FloodRescueApp());
}

class FloodRescueApp extends StatelessWidget {
  const FloodRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống Cứu hộ Lũ lụt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0288D1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0288D1),
          primary: const Color(0xFF0288D1),
          secondary: const Color(0xFF03A9F4),
          surface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F7FF),
      ),
      home: const HomeScreen(), // Khởi đầu bằng Trang chủ nguyên bản
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/notification_management_screen.dart';
import 'screens/admin/system_dashboard_screen.dart';

void main() {
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
      home: const HomeScreen(),
      routes: {
        '/admin/users': (context) => const UserManagementScreen(),
        '/admin/notifications': (context) => const NotificationManagementScreen(),
        '/admin/dashboard': (context) => const SystemDashboardScreen(),
      },
    );
  }
}

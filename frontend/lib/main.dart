import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/notification_management_screen.dart';
import 'screens/admin/system_dashboard_screen.dart';
import 'screens/admin/vehicle_management_screen.dart';
import 'screens/admin/vehicle_location_screen.dart';
import 'screens/admin/role_management_screen.dart';
import 'screens/admin/warehouse_management_screen.dart';

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
      home: const HomeScreen(),
      routes: {
        '/admin/users': (context) => const UserManagementScreen(),
        '/admin/roles': (context) => const RoleManagementScreen(),
        '/admin/notifications': (context) => const NotificationManagementScreen(),
        '/admin/dashboard': (context) => const SystemDashboardScreen(),
        '/admin/vehicles': (context) => const VehicleManagementScreen(),
        '/admin/vehicle_locations': (context) => const VehicleLocationScreen(),
        '/admin/warehouses': (context) => const WarehouseManagementScreen(),
      },
    );
  }
}

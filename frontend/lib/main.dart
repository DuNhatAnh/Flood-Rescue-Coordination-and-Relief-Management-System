import 'package:flutter/material.dart';
import 'package:flood_rescue_app/components/protected_route.dart';
import 'package:flood_rescue_app/models/user_model.dart';
import 'package:flood_rescue_app/screens/coordinator/coordinator_dashboard.dart';
import 'package:flood_rescue_app/screens/rescue_team/staff_main_screen.dart';
import 'screens/home_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/notification_management_screen.dart';
import 'screens/admin/system_dashboard_screen.dart';
import 'screens/admin/vehicle_management_screen.dart';
import 'screens/admin/vehicle_location_screen.dart';
import 'screens/admin/role_management_screen.dart';
import 'screens/admin/warehouse_management_screen.dart';
import 'package:flood_rescue_app/screens/coordinator/analytics_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';
import 'screens/admin/danger_point_management_screen.dart';
import 'screens/admin/system_settings_screen.dart';

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
        // Admin Protected Routes
        '/admin/dashboard': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: SystemDashboardScreen(),
        ),
        '/admin/users': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: UserManagementScreen(),
        ),
        '/admin/roles': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: RoleManagementScreen(),
        ),
        '/admin/notifications': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: NotificationManagementScreen(),
        ),
        '/admin/vehicles': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: VehicleManagementScreen(),
        ),
        '/admin/vehicle_locations': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: VehicleLocationScreen(),
        ),
        '/admin/warehouses': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: WarehouseManagementScreen(),
        ),
        '/admin/analytics': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: AdminAnalyticsScreen(),
        ),
        '/admin/danger-points': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: DangerPointManagementScreen(),
        ),
        '/admin/settings': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.admin],
          child: SystemSettingsScreen(),
        ),

        // Coordinator Protected Routes
        '/coordinator/dashboard': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.coordinator, UserRole.admin],
          child: CoordinatorDashboard(),
        ),
        '/coordinator/analytics': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.coordinator, UserRole.admin],
          child: AnalyticsScreen(),
        ),

        // Staff Protected Routes
        '/staff/dashboard': (context) => const ProtectedRoute(
          allowedRoles: [UserRole.rescueStaff, UserRole.admin],
          child: StaffMainScreen(),
        ),
      },
    );
  }
}

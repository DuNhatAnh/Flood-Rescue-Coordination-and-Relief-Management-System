import 'package:flutter/material.dart';
import 'warehouse_screen.dart';
import 'team_tasks_screen.dart';
import 'staff_managed_warehouse_screen.dart';
import 'staff_report_screen.dart';
import '../relief_item_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../utils/staff_theme.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({Key? key}) : super(key: key);

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _selectedIndex = 0; // Mặc định vào tab Nhiệm vụ

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const TeamTasksScreen(),
      const StaffManagedWarehouseScreen(),
      const StaffReportScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() {
    AuthService.currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: StaffTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        title: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('XIN CHÀO, ĐỘI CỨU HỘ', style: StaffTheme.subtitleSmall, overflow: TextOverflow.ellipsis),
              Text(
                _getTabTitle(),
                style: StaffTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'logout') _handleLogout();
                if (val == 'catalog') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReliefItemScreen()),
                  );
                }
              },
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white30,
                  child: Icon(Icons.person_rounded, size: 20, color: Colors.white),
                ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nhân viên cứu hộ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(AuthService.currentUser?.email ?? 'Staff Account', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'catalog',
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: StaffTheme.primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Text('Danh mục hàng', style: StaffTheme.cardSubtitle.copyWith(color: StaffTheme.textDark)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: StaffTheme.errorRed, size: 20),
                      SizedBox(width: 12),
                      Text('Đăng xuất', style: TextStyle(color: StaffTheme.errorRed, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.assignment_rounded, 'Nhiệm vụ'),
            _buildNavItem(1, Icons.warehouse_rounded, 'Kho bãi'),
            _buildNavItem(2, Icons.analytics_rounded, 'Thống kê'),
          ],
        ),
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedIndex) {
      case 0: return 'Nhiệm vụ được giao';
      case 1: return 'Quản lý Kho bãi';
      case 2: return 'Thống kê & Lịch sử';
      default: return 'Staff Dashboard';
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    Color color = isSelected ? StaffTheme.primaryBlue : StaffTheme.textLight;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? StaffTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

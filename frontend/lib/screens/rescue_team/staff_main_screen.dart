import 'package:flutter/material.dart';
import 'warehouse_screen.dart';
import 'team_tasks_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({Key? key}) : super(key: key);

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<WarehouseScreenState> _warehouseKey = GlobalKey<WarehouseScreenState>();
  final GlobalKey<TeamTasksScreenState> _teamTasksKey = GlobalKey<TeamTasksScreenState>();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WarehouseScreen(key: _warehouseKey),
      TeamTasksScreen(key: _teamTasksKey),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _selectedIndex == 0
                  ? [const Color(0xFF0288D1), const Color(0xFF03A9F4)]
                  : [const Color(0xFF43A047), const Color(0xFF66BB6A)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'XIN CHÀO, ĐỘI CỨU HỘ',
              style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedIndex == 0 ? 'Điều phối Kho hàng' : 'Quản lý Nhiệm vụ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Refresh Button - Styled as a subtle action
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 22),
            onPressed: () {
              if (_selectedIndex == 0) {
                _warehouseKey.currentState?.loadWarehouses();
              } else {
                _teamTasksKey.currentState?.refreshTasks();
              }
            },
            tooltip: 'Cập nhật dữ liệu',
          ),
          // User Profile / Logout - Grouped for premium feel
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'logout') _handleLogout();
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
                      Text('Staff Account', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _warehouseKey.currentState?.showAddDialog(),
              backgroundColor: const Color(0xFF0288D1),
              elevation: 4,
              heroTag: 'add_warehouse_btn',
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
              label: const Text('Thêm Kho mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded, 'Kho bãi'),
            _buildNavItem(1, Icons.assignment_turned_in_rounded, 'Nhiệm vụ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    Color color = isSelected ? const Color(0xFF0288D1) : Colors.grey.shade400;
    
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
              color: isSelected ? const Color(0xFF0288D1).withOpacity(0.1) : Colors.transparent,
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

import 'package:flutter/material.dart';
import 'warehouse_screen.dart';
import 'team_tasks_screen.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XIN CHÀO, ĐỘI CỨU HỘ', style: StaffTheme.subtitleSmall),
            Text(
              _selectedIndex == 0 ? 'Điều phối Kho hàng' : 'Quản lý Nhiệm vụ',
              style: StaffTheme.titleLarge,
            ),
          ],
        ),
        actions: [
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
                      Text('Staff Account', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _warehouseKey.currentState?.showAddDialog(),
              backgroundColor: StaffTheme.primaryBlue,
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
          boxShadow: StaffTheme.softShadow,
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

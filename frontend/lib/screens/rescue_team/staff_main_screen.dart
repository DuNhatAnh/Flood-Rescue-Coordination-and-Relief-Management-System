import 'package:flutter/material.dart';
import '../relief_item_screen.dart';
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
  final GlobalKey<ReliefItemScreenState> _reliefItemKey = GlobalKey<ReliefItemScreenState>();
  final GlobalKey<TeamTasksScreenState> _teamTasksKey = GlobalKey<TeamTasksScreenState>();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ReliefItemScreen(key: _reliefItemKey),
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _selectedIndex == 0
                  ? [const Color(0xFF0288D1), const Color(0xFF03A9F4)]
                  : [const Color(0xFF43A047), const Color(0xFF66BB6A)],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          _selectedIndex == 0 ? 'Quản lý Kho hàng' : 'Nhiệm vụ Đội cứu hộ',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (_selectedIndex == 0) {
                _reliefItemKey.currentState?.loadItems();
              } else {
                _teamTasksKey.currentState?.refreshTasks();
              }
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _reliefItemKey.currentState?.showAddDialog(),
              backgroundColor: const Color(0xFF0288D1),
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Thêm hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0288D1),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse_rounded),
              activeIcon: Icon(Icons.warehouse_rounded),
              label: 'Kho hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Nhiệm vụ',
            ),
          ],
        ),
      ),
    );
  }
}

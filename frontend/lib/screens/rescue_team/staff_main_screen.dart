import 'package:flutter/material.dart';
import 'team_tasks_screen.dart';
import 'staff_managed_warehouse_screen.dart';
import 'staff_report_screen.dart';
// Đã loại bỏ import trang phương tiện
import '../relief_item_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../utils/staff_theme.dart';
import '../../services/rescue_service.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'notification_screen.dart';
import 'dart:async';


class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({Key? key}) : super(key: key);

  @override
  State<StaffMainScreen> createState() => StaffMainScreenState();
}

class StaffMainScreenState extends State<StaffMainScreen> {
  int _selectedIndex = 0; // Mặc định vào tab Nhiệm vụ
  
  // Khai báo các Key để có thể gọi hàm refresh từ bên ngoài
  final GlobalKey<TeamTasksScreenState> _tasksKey = GlobalKey();
  final GlobalKey<StaffManagedWarehouseScreenState> _warehouseKey = GlobalKey();
  final GlobalKey<StaffReportScreenState> _reportKey = GlobalKey();
  
  final RescueService _rescueService = RescueService();
  final NotificationService _notificationService = NotificationService();
  String _teamName = AuthService.currentUser?.teamName ?? 'ĐỘI CỨU HỘ';
  int _unreadNotifications = 0;
  Timer? _notificationTimer;
  String? _lastNotificationId;


  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Danh sách màn hình đã loại bỏ StaffVehicleManagementScreen
    _screens = [
      TeamTasksScreen(key: _tasksKey),
      StaffManagedWarehouseScreen(key: _warehouseKey),
      StaffReportScreen(key: _reportKey),
    ];
    _fetchTeamName();
    _checkNotifications();
    // Kiểm tra thông báo mới mỗi 30 giây
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNotifications() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) return;

    try {
      final count = await _notificationService.getUnreadCount(userId);
      
      if (count > _unreadNotifications) {
        final list = await _notificationService.getUserNotifications(userId);
        if (list.isNotEmpty && list.first.id != _lastNotificationId) {
          _lastNotificationId = list.first.id;
          _showNotificationDialog(list.first);
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (e) {
      debugPrint('Lỗi check notifications: $e');
    }
  }

  void _showNotificationDialog(NotificationModel notification) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: StaffTheme.primaryBlue),
            const SizedBox(width: 8),
            const Text('Thông báo mới'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title ?? 'Cập nhật hệ thống', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(notification.content ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffNotificationScreen()))
                .then((_) => _checkNotifications());
            },
            child: const Text('Xem danh sách'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: StaffTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTeamName() async {
    final teamId = AuthService.currentUser?.teamId;
    if (teamId == null) return;
    
    final teamData = await _rescueService.getTeamById(teamId);
    if (teamData != null && teamData['teamName'] != null) {
      if (!mounted) return;
      setState(() {
        _teamName = teamData['teamName'];
        final current = AuthService.currentUser;
        if (current != null) {
          AuthService.currentUser = UserModel(
            id: current.id,
            fullName: current.fullName,
            email: current.email,
            teamId: current.teamId,
            teamName: _teamName,
            role: current.role,
          );
        }
      });
    }
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
        centerTitle: true,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('XIN CHÀO', style: StaffTheme.subtitleSmall),
            Text(
              _teamName.toUpperCase(),
              style: StaffTheme.titleLarge.copyWith(fontSize: 24, letterSpacing: 1.2),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StaffNotificationScreen()),
                    ).then((_) => _checkNotifications());
                  },
                  tooltip: 'Thông báo',
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_unreadNotifications',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              // Cập nhật logic refresh cho 3 tab
              if (_selectedIndex == 0) {
                _tasksKey.currentState?.refreshTasks();
              } else if (_selectedIndex == 1) {
                _warehouseKey.currentState?.refreshData();
              } else if (_selectedIndex == 2) {
                _reportKey.currentState?.refreshData();
              }
              _fetchTeamName();
              _checkNotifications();
            },
            tooltip: 'Tải lại dữ liệu',
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
                      const Text('Danh mục hàng'),
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
        height: 80, // Điều chỉnh chiều cao cho 3 mục
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? StaffTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
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
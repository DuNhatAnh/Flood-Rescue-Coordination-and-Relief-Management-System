import 'package:flutter/material.dart';
import 'rescue_request_screen.dart';
import 'coordinator/coordinator_dashboard.dart';
import 'rescue_team/team_tasks_screen.dart';
import 'auth/login_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const StatBoard(),
                  const MainContent(),
                ],
              ),
            ),
          ),
          const BottomBar(),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.tsunami, color: Color(0xFF0288D1), size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flood Rescue System',
                style: TextStyle(
                  color: Color(0xFF01579B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Emergency Coordination & Relief Management',
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng Báo an toàn đang được phát triển')),
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Báo an toàn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1F5FE),
              foregroundColor: const Color(0xFF0288D1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RescueRequestScreen()),
              );
            },
            icon: const Icon(Icons.emergency_share, size: 18),
            label: const Text('Báo cần hỗ trợ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.red.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.account_circle_outlined, size: 20),
            label: const Text('Đăng nhập'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF546E7A),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => _navigateToModule(context, const CoordinatorDashboard(), UserRole.coordinator),
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
            label: const Text('Điều phối'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[800],
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => _navigateToModule(context, const TeamTasksScreen(), UserRole.rescueStaff),
            icon: const Icon(Icons.engineering_outlined, size: 20),
            label: const Text('Đội cứu hộ'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[800],
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToModule(BuildContext context, Widget screen, UserRole requiredRole) {
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để truy cập tính năng này!'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
}

class StatBoard extends StatelessWidget {
  const StatBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Row(
        children: [
          const Expanded(
              child: StatCard(
                  title: 'Đang tiếp nhận',
                  count: 0,
                  icon: Icons.pending_outlined,
                  color: Color(0xFFFF8A65))),
          const SizedBox(width: 20),
          const Expanded(
              child: StatCard(
                  title: 'Đã hỗ trợ',
                  count: 0,
                  icon: Icons.volunteer_activism_outlined,
                  color: Color(0xFF66BB6A))),
          const SizedBox(width: 20),
          const Expanded(
              child: StatCard(
                  title: 'Người được hỗ trợ',
                  count: 0,
                  icon: Icons.groups_outlined,
                  color: Color(0xFF42A5F5))),
          const SizedBox(width: 20),
          const Expanded(
              child: StatCard(
                  title: 'Báo an toàn',
                  count: 0,
                  icon: Icons.verified_user_outlined,
                  color: Color(0xFF26A69A))),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F9FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.map_rounded, size: 70, color: Colors.blue[200]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bản đồ đang được khởi tạo',
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống đang kết nối với các trạm cứu trợ thực địa...',
              style: TextStyle(color: Colors.blueGrey[300], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.blue.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bottomLink('Giới thiệu'),
          _divider(),
          _bottomLink('Hướng dẫn nhận tin'),
          _divider(),
          _bottomLink('Hỗ trợ kỹ thuật'),
          _divider(),
          _bottomLink('Facebook'),
        ],
      ),
    );
  }

  Widget _bottomLink(String label) {
    return InkWell(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blueGrey[600],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 4,
      width: 4,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        shape: BoxShape.circle,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

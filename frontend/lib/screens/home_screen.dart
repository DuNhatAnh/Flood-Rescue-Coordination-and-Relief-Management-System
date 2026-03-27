import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui_web' as ui_web;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flood_rescue_app/screens/rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/track_rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/auth/login_screen.dart';
import 'package:flood_rescue_app/screens/citizen/safety_report_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';
import 'package:flood_rescue_app/models/user_model.dart';
import 'package:flood_rescue_app/screens/coordinator/coordinator_dashboard.dart';
import 'package:flood_rescue_app/screens/rescue_team/staff_main_screen.dart';
import 'package:flood_rescue_app/screens/admin/system_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          TopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StatBoard(),
                  MainContent(),
                ],
              ),
            ),
          ),
          BottomBar(),
        ],
      ),
    );
  }
}



class TopBar extends StatefulWidget {
  const TopBar({Key? key}) : super(key: key);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

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
                'Flood Rescue System v2.0',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TrackRescueRequestScreen()),
              );
            },
            icon: const Icon(Icons.track_changes, size: 18),
            label: const Text('Theo dõi cứu hộ'),
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
                    builder: (context) => const SafetyReportScreen()),
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Báo an toàn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F5E9),
              foregroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chuyển đến trang báo cần hỗ trợ...'), duration: Duration(milliseconds: 1000)),
              );
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
          if (user?.role == UserRole.admin)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/dashboard');
              },
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: const Text('Quản lý hệ thống'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF2E7D32),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(width: 12),
          user != null
              ? Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final role = user.role;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang vào hệ thống với vai trò: $role'), duration: const Duration(milliseconds: 1500)),
                        );

                        // Explicitly handle each role for maximum reliability
                        if (role == UserRole.coordinator) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CoordinatorDashboard()),
                          );
                        } else if (role == UserRole.admin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SystemDashboardScreen()),
                          );
                        } else if (role == UserRole.rescueStaff) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StaffMainScreen()),
                          );
                        } else {
                          // For regular users, maybe take them to their request history?
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TrackRescueRequestScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.dashboard_outlined, size: 20),
                      label: Text(user.role == UserRole.coordinator 
                          ? 'Trang Điều phối' 
                          : (user.role == UserRole.admin ? 'Dashboard Cứu hộ' : 'Trang Cứu hộ')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01579B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await AuthService.logout();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
                      tooltip: 'Đăng xuất',
                    ),
                  ],
                )
              : TextButton.icon(
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
                    foregroundColor: const Color(0xFF01579B),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
        ],
      ),
    );
  }
}

class StatBoard extends StatefulWidget {
  const StatBoard({Key? key}) : super(key: key);

  @override
  State<StatBoard> createState() => _StatBoardState();
}

class _StatBoardState extends State<StatBoard> {
  int pendingCount = 0;
  int completedCount = 0;
  int peopleSupported = 0;
  int safeReports = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/v1/rescue-requests/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stats = data['data'];
          if (mounted) {
            setState(() {
              pendingCount = stats['pending'] ?? 0;
              completedCount = stats['completed'] ?? 0;
              peopleSupported = stats['peopleSupported'] ?? 0;
              safeReports = stats['safeReports'] ?? 0;
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // Handle error quietly or show 0
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Row(
        children: [
          Expanded(
              child: StatCard(
                  title: 'Đang tiếp nhận',
                  count: pendingCount,
                  icon: Icons.pending_outlined,
                  color: const Color(0xFFFF8A65))),
          const SizedBox(width: 20),
          Expanded(
              child: StatCard(
                  title: 'Đã hỗ trợ',
                  count: completedCount,
                  icon: Icons.volunteer_activism_outlined,
                  color: const Color(0xFF66BB6A))),
          const SizedBox(width: 20),
          Expanded(
              child: StatCard(
                  title: 'Người được hỗ trợ',
                  count: peopleSupported,
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF42A5F5))),
          const SizedBox(width: 20),
          Expanded(
              child: StatCard(
                  title: 'Báo an toàn',
                  count: safeReports,
                  icon: Icons.verified_user_outlined,
                  color: const Color(0xFF26A69A))),
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

class MainContent extends StatefulWidget {
  const MainContent({Key? key}) : super(key: key);

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  late String _mapViewId;

  @override
  void initState() {
    super.initState();
    _mapViewId = 'leaflet-map-${DateTime.now().millisecondsSinceEpoch}';

    // Register the div element for Leaflet
    final html.DivElement mapElement = html.DivElement()
      ..id = _mapViewId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '24px';

    ui_web.platformViewRegistry.registerViewFactory(
      _mapViewId,
      (int viewId) => mapElement,
    );

    // Call JS init script after rendering with multiple attempts
    _initMapWithRetry(mapElement, 0);
  }

  void _initMapWithRetry(html.DivElement element, int attempt) {
    if (attempt > 5) return; // Stop after 5 attempts
    
    Future.delayed(Duration(milliseconds: 300 * (attempt + 1)), () {
      try {
        if (js.context.hasProperty('initLeafletMap')) {
          js.context.callMethod('initLeafletMap', [element]);
        } else {
          _initMapWithRetry(element, attempt + 1);
        }
      } catch (e) {
        _initMapWithRetry(element, attempt + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.blue.withOpacity(0.1)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: HtmlElementView(viewType: _mapViewId),
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

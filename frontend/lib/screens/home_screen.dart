import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flood_rescue_app/screens/rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/track_rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/auth/login_screen.dart';
import 'package:flood_rescue_app/screens/citizen/safety_report_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';
import 'package:flood_rescue_app/models/user_model.dart';

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
          AuthService.currentUser != null
              ? Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.dashboard_outlined, size: 20),
                      label: Text(AuthService.currentUser!.role == UserRole.coordinator 
                          ? 'Trang Điều phối' 
                          : 'Trang Cứu hộ'),
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
                        // (context as Element).markNeedsBuild(); // Force rebuild to show login button
                        // Or better, since TopBar is a StatelessWidget, we might need a better way to refresh HomeScreen.
                        // For simplicity, let's just push Home again or notify user.
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
  @override
  void initState() {
    super.initState();
    // Register the div element for Leaflet
    ui.platformViewRegistry.registerViewFactory(
      'leaflet-map',
      (int viewId) => html.DivElement()
        ..id = 'map'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '24px',
    );

    // Call JS init script after rendering
    Future.delayed(const Duration(milliseconds: 500), () {
      js.context.callMethod('initLeafletMap');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650, // Increased from 520
      margin: const EdgeInsets.symmetric(vertical: 10), // Removed horizontal margin
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.blue.withOpacity(0.1)),
        ),
      ),
      child: const HtmlElementView(viewType: 'leaflet-map'),
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

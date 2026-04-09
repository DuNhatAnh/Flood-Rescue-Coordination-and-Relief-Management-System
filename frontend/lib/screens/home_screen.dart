import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import 'package:flood_rescue_app/screens/rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/track_rescue_request_screen.dart';
import 'package:flood_rescue_app/screens/auth/login_screen.dart';
import 'package:flood_rescue_app/screens/citizen/safety_report_screen.dart';
import 'package:flood_rescue_app/services/auth_service.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';
import 'package:flood_rescue_app/models/safety_report.dart';
import 'package:flood_rescue_app/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const MapTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF0288D1),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Bản đồ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: HOME TAB (User-Centric) ---
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(),
            const SOSSection(),
            const QuickActions(),
            const EmergencyHotline(),
            const StatBoard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 15, 16, 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blue[50]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hệ thống',
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Text(
                'Cứu hộ Lũ lụt 24/7',
                style: TextStyle(
                  color: Color(0xFF01579B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF03A9F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.waves, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SOSSection extends StatelessWidget {
  const SOSSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emergency_share, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'CỨU HỘ KHẨN CẤP (SOS)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nếu bạn hoặc người xung quanh đang gặp nguy hiểm tính mạng',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RescueRequestScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('GỬI YÊU CẦU NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch vụ của chúng tôi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  context,
                  'Theo dõi cứu hộ',
                  'Tra cứu trạng thái',
                  Icons.track_changes,
                  const Color(0xFFE1F5FE),
                  const Color(0xFF0288D1),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrackRescueRequestScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionCard(
                  context,
                  'Báo an toàn',
                  'Thông tin cứu trợ',
                  Icons.verified_user_outlined,
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyReportScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, String subtitle, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: text, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: text)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: text.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: MAP TAB ---
class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final RescueService _rescueService = RescueService();
  final MapController _mapController = MapController();
  List<RescueRequest> _requests = [];
  List<SafetyReport> _safetyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _rescueService.getAllRequests();
      final reports = await _rescueService.getSafetyReports();
      if (mounted) {
        setState(() {
          _requests = requests;
          _safetyReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMarkerDetail(dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item is RescueRequest ? 'Yêu cầu: ${item.citizenName}' : 'Vị trí an toàn: ${item.citizenName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (item is RescueRequest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.urgencyLabel,
                      style: TextStyle(color: item.urgencyColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(item.address, style: const TextStyle(color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 16),
            if (item is RescueRequest)
              Text(item.description.isNotEmpty ? item.description : 'Không có mô tả chi tiết'),
            if (item is SafetyReport)
              Text(item.note != null && item.note!.isNotEmpty ? item.note! : 'Được xác nhận là khu vực an toàn'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${item.phone}')),
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi hỗ trợ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(15.6, 108.5),
            initialZoom: 11.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'vn.flood.rescue.project.v1',
            ),
            MarkerLayer(
              markers: [
                // Markers for Rescue Requests
                ..._requests.map((req) => Marker(
                  point: LatLng(req.lat, req.lng),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showMarkerDetail(req),
                    child: Icon(
                      Icons.location_on,
                      color: req.urgencyColor,
                      size: 40,
                    ),
                  ),
                )),
                // Markers for Safety Reports
                ..._safetyReports.where((rep) => rep.lat != null && rep.lng != null).map((rep) => Marker(
                  point: LatLng(rep.lat!, rep.lng!),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showMarkerDetail(rep),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
        // Overlay Search Bar
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.radar, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tình hình cứu hộ thực tế',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchData,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// --- TAB 3: PROFILE TAB ---
class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Tài khoản của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, size: 60, color: Colors.blue.shade800),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'Khách',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'Chưa đăng nhập',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            if (user != null) ...[
              _menuItem(Icons.dashboard_outlined, 'Vào hệ thống quản lý', () {
                final role = user.role;
                if (role == UserRole.coordinator) {
                  Navigator.pushNamed(context, '/coordinator/dashboard');
                } else if (role == UserRole.admin) {
                  Navigator.pushNamed(context, '/admin/dashboard');
                } else if (role == UserRole.rescueStaff) {
                  Navigator.pushNamed(context, '/staff/dashboard');
                }
              }),
              _menuItem(Icons.history, 'Lịch sử yêu cầu cứu trợ', () {}),
              _menuItem(Icons.logout, 'Đăng xuất', () async {
                await AuthService.logout();
                if (mounted) setState(() {});
              }, color: Colors.red),
            ] else ...[
              _menuItem(Icons.login, 'Đăng nhập hệ thống', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }),
            ],
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            _menuItem(Icons.info_outline, 'Giới thiệu về hệ thống', () {}),
            _menuItem(Icons.support_agent, 'Hỗ trợ kỹ thuật', () {}),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {Color color = const Color(0xFF263238)}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

// --- TAB 5: EMERGENCY HOTLINE ---
class EmergencyHotline extends StatelessWidget {
  const EmergencyHotline({Key? key}) : super(key: key);

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đường dây nóng hỗ trợ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _hotlineItem(
                  '086.777.9427', 
                  'Hotline Cứu hộ khẩn cấp 24/7', 
                  const Color(0xFF673AB7), 
                  () => _makeCall('0867779427')
                ),
                const Divider(height: 24),
                _hotlineItem(
                  '112', 
                  'Tìm kiếm & Cứu nạn Quốc gia', 
                  Colors.orange, 
                  () => _makeCall('112')
                ),
                const Divider(height: 24),
                _hotlineItem(
                  '114', 
                  'Cứu hỏa & Cứu hộ khẩn cấp', 
                  Colors.red, 
                  () => _makeCall('114')
                ),
                const Divider(height: 24),
                _hotlineItem(
                  '115', 
                  'Cấp cứu Y tế', 
                  Colors.blue, 
                  () => _makeCall('115')
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hotlineItem(String number, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_in_talk, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'GỌI NGAY',
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.bold, 
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: color, size: 16),
        ],
      ),
    );
  }
}

// --- SUB-COMPONENTS ---
class StatBoard extends StatefulWidget {
  const StatBoard({Key? key}) : super(key: key);

  @override
  State<StatBoard> createState() => _StatBoardState();
}

class _StatBoardState extends State<StatBoard> {
  int pendingCount = 0;
  int completedCount = 0;
  int peopleSupported = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('${Constants.apiV1}/rescue-requests/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stats = data['data'];
          if (mounted) {
            setState(() {
              pendingCount = stats['pending'] ?? 0;
              completedCount = stats['completed'] ?? 0;
              peopleSupported = stats['peopleSupported'] ?? 0;
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tin tức & Thống kê cứu hộ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _miniStatCard('Đang xử lý', pendingCount, Icons.pending_actions, Colors.orange),
          const SizedBox(height: 12),
          _miniStatCard('Đã cứu trợ thành công', completedCount, Icons.check_circle_outline, Colors.green),
          const SizedBox(height: 12),
          _miniStatCard('Tổng số người được hỗ trợ', peopleSupported, Icons.groups, Colors.blue),
        ],
      ),
    );
  }

  Widget _miniStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500))),
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
        ],
      ),
    );
  }
}

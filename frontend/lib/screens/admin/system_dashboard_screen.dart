import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';


class SystemDashboardScreen extends StatefulWidget {
  const SystemDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SystemDashboardScreen> createState() => _SystemDashboardScreenState();
}

class _SystemDashboardScreenState extends State<SystemDashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.fetchSystemStats();
      final logs = await _adminService.fetchSystemLogs();
      if (mounted) {
        setState(() {
          _stats = stats;
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int statCrossAxisCount = screenWidth > 800 ? 4 : 2; // Trả về 4 cột để kích thước ô nhỏ lại như cũ
    int navCrossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 4 : 2);
    double childAspectRatio = screenWidth > 800 ? 1.8 : (screenWidth < 600 ? 1.1 : 1.5);
    double navAspectRatio = screenWidth > 800 ? 1.5 : (screenWidth < 600 ? 1.0 : 2.0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Loại bỏ nút mũi tên quay lại
        title: const Text('Dashboard Hệ thống'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (screenWidth > 600)
            TextButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Đăng xuất',
            ),
          const SizedBox(width: 5),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng quan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  if (_stats != null)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: statCrossAxisCount,
                      childAspectRatio: childAspectRatio,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          context,
                          'Người dùng',
                          '${_stats!['totalUsers']}',
                          Icons.people,
                          Colors.blue,
                          screenWidth,
                        ),
                        _buildStatCard(
                          context,
                          'Đội cứu hộ',
                          '${_stats!['totalTeams']}',
                          Icons.security,
                          Colors.deepPurple,
                          screenWidth,
                        ),
                      ],
                    ),
                    
                  const SizedBox(height: 36),
                  const Text('Quản lý hệ thống', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2),
                    childAspectRatio: navAspectRatio,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildNavBtn(context, 'Báo cáo', Icons.analytics, '/admin/analytics', Colors.pink, screenWidth),
                      _buildNavBtn(context, 'Người dùng', Icons.manage_accounts, '/admin/users', Colors.indigo, screenWidth),
                      _buildNavBtn(context, 'Kho bãi', Icons.warehouse, '/admin/warehouses', Colors.orange, screenWidth),
                      _buildNavBtn(context, 'Thông báo', Icons.notifications_active, '/admin/notifications', Colors.teal, screenWidth),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF2555D4)),
                      SizedBox(width: 8),
                      Text('Nhật ký hệ thống', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.length > 15 ? 15 : _logs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.withOpacity(0.15),
                            child: const Icon(Icons.bolt, color: Colors.blue, size: 24),
                          ),
                          title: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(log['details'], style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                          ),
                          trailing: Text(log['createdAt'].toString().substring(0, 10), style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, double screenWidth, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth < 600 ? 8 : 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(icon, color: color, size: screenWidth < 600 ? 24 : 32),
                  ),
                  Expanded(
                    child: Text(
                      value, 
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(BuildContext context, String title, IconData icon, String route, Color color, double screenWidth) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 3,
        shadowColor: color.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5)
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth < 600 ? 10 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: screenWidth < 600 ? 28 : 32),
          ),
          SizedBox(height: screenWidth < 600 ? 8 : 16),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: screenWidth < 600 ? 16 : 18, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

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
      setState(() {
        _stats = stats;
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int statCrossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 4 : 2);
    int navCrossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 4 : 2);
    double childAspectRatio = screenWidth > 800 ? 1.8 : 1.5;
    double navAspectRatio = screenWidth > 800 ? 1.5 : 2.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Hệ thống'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
        elevation: 0,
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
                        _buildStatCard('Người dùng', '${_stats!['totalUsers']}', Icons.people, Colors.blue),
                        _buildStatCard('Đội cứu hộ', '${_stats!['totalTeams']}', Icons.security, Colors.deepPurple),
                        _buildStatCard('Tổng yêu cầu', '${_stats!['totalRequests']}', Icons.list_alt, Colors.orange),
                        _buildStatCard('Đang xử lý', '${_stats!['pendingRequests']}', Icons.pending_actions, Colors.redAccent),
                      ],
                    ),
                  const SizedBox(height: 36),
                  const Text('Quản lý', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: navCrossAxisCount,
                    childAspectRatio: navAspectRatio,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildNavBtn(context, 'Người dùng', Icons.manage_accounts, '/admin/users', Colors.indigo),
                      _buildNavBtn(context, 'Thông báo', Icons.notifications_active, '/admin/notifications', Colors.teal),
                      _buildNavBtn(context, 'Phương tiện', Icons.directions_car, '/admin/vehicles', Colors.blueGrey),
                      _buildNavBtn(context, 'Bản đồ xe', Icons.map, '/admin/vehicle_locations', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: const [
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
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              Expanded(
                child: Text(
                  value, 
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNavBtn(BuildContext context, String title, IconData icon, String route, Color color) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

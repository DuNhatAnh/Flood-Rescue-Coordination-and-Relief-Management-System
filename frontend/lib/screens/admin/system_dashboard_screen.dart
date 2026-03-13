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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Hệ thống')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thống kê tổng quan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_stats != null)
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildStatCard('Người dùng', '${_stats!['totalUsers']}'),
                        _buildStatCard('Yêu cầu SOS', '${_stats!['totalRequests']}'),
                        _buildStatCard('Đang xử lý', '${_stats!['pendingRequests']}'),
                        _buildStatCard('Đã hoàn thành', '${_stats!['completedRequests']}'),
                        _buildStatCard('Đội cứu hộ', '${_stats!['totalTeams']}'),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/admin/users'),
                        icon: const Icon(Icons.people),
                        label: const Text('Quản lý User'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/admin/notifications'),
                        icon: const Icon(Icons.notifications),
                        label: const Text('Thông báo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Nhật ký hệ thống gần đây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length > 10 ? 10 : _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(log['action']),
                        subtitle: Text(log['details']),
                        trailing: Text(log['createdAt'].toString().substring(0, 10)),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

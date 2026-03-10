import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../services/rescue_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'rescue_report_screen.dart';

class TeamTasksScreen extends StatefulWidget {
  const TeamTasksScreen({Key? key}) : super(key: key);

  @override
  State<TeamTasksScreen> createState() => _TeamTasksScreenState();
}

class _TeamTasksScreenState extends State<TeamTasksScreen> {
  final RescueService _rescueService = RescueService();
  late Future<List<Assignment>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _rescueService.getMyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm Vụ Của Tôi'),
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              AuthService.currentUser = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
          IconButton(onPressed: _refreshTasks, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('Bạn chưa có nhiệm vụ nào được phân công.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Assignment task) {
    final timeStr = DateFormat('dd/MM HH:mm').format(task.assignedAt);
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ĐANG THỰC HIỆN',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Yêu cầu cứu hộ #1', // Trong thực tế sẽ fetch detail request
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blue),
                SizedBox(width: 5),
                Text('123 Hùng Vương, Đà Nẵng'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_boat, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text('Phương tiện: Xuồng Máy (DN-001)'),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Xem bản đồ đường đi
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Bản đồ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RescueReportScreen()),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Báo cáo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

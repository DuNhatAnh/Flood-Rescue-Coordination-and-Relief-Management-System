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
  TeamTasksScreenState createState() => TeamTasksScreenState();
}

class TeamTasksScreenState extends State<TeamTasksScreen> {
  final RescueService _rescueService = RescueService();
  late Future<List<Assignment>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    refreshTasks();
  }

  void refreshTasks() {
    setState(() {
      _tasksFuture = _rescueService.getMyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Assignment>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF43A047)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('Không thể tải nhiệm vụ: ${snapshot.error}', textAlign: TextAlign.center),
                TextButton(onPressed: refreshTasks, child: const Text('Thử lại'))
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Bạn chưa có nhiệm vụ nào',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mọi thứ đều đã hoàn tất! Nghỉ ngơi nhé.',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Assignment task) {
    final timeStr = DateFormat('dd/MM HH:mm').format(task.assignedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.orange.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ĐANG THỰC HIỆN',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Text(timeStr, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yêu cầu cứu hộ #1',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 12),
                  _buildIconText(Icons.location_on_rounded, '123 Hùng Vương, Đà Nẵng', Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildIconText(Icons.directions_boat_rounded, 'Phương tiện: Xuồng Máy (DN-001)', Colors.blue),
                  const Divider(height: 32, thickness: 0.8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue.shade200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.map_rounded, size: 20),
                          label: const Text('Bản đồ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RescueReportScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.assignment_turned_in_rounded, size: 20, color: Colors.white),
                          label: const Text('Báo cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF455A64), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

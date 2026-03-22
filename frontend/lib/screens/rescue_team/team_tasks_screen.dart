import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../services/rescue_service.dart';
import '../../utils/staff_theme.dart';
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
    return Scaffold(
      backgroundColor: StaffTheme.background,
      body: FutureBuilder<List<Assignment>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: StaffTheme.primaryBlue));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: StaffTheme.errorRed),
                  const SizedBox(height: 16),
                  Text('Không thể tải nhiệm vụ', style: StaffTheme.cardSubtitle),
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
                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('Bạn chưa có nhiệm vụ nào', style: StaffTheme.cardTitle.copyWith(color: StaffTheme.textLight)),
                  const SizedBox(height: 8),
                  Text('Mọi thứ đều đã hoàn tất! Nghỉ ngơi nhé.', style: StaffTheme.cardSubtitle),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => refreshTasks(),
            color: StaffTheme.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Assignment task) {
    final timeStr = DateFormat('dd/MM HH:mm').format(task.assignedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StaffTheme.cardRadius),
        border: Border.all(color: StaffTheme.border),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Professional Ledger Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StaffTheme.warningOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_late_rounded, color: StaffTheme.warningOrange.withOpacity(0.7), size: 32),
                ),
                const SizedBox(width: 16),
                // Task Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('NHIỆM VỤ #${task.id.toString().substring(0, 4) ?? "NEW"}', style: StaffTheme.cardTitle),
                          Text(timeStr, style: const TextStyle(color: StaffTheme.textLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildIconText(Icons.location_on_rounded, '123 Hùng Vương, Đà Nẵng', StaffTheme.errorRed),
                      const SizedBox(height: 4),
                      _buildIconText(Icons.directions_boat_rounded, 'Xuồng Máy (DN-001)', StaffTheme.primaryBlue),
                      const SizedBox(height: 12),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: StaffTheme.warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ĐANG THỰC HIỆN',
                          style: TextStyle(color: StaffTheme.warningOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: StaffTheme.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: StaffTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18, color: StaffTheme.primaryBlue),
                    label: const Text('BẢN ĐỒ', style: TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
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
                      backgroundColor: StaffTheme.successGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Colors.white),
                    label: const Text('BÁO CÁO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: StaffTheme.textMedium, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

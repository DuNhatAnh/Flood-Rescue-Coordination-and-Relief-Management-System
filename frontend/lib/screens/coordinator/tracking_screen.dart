import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flood_rescue_app/models/assignment.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final RescueService _rescueService = RescueService();
  List<Assignment> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _rescueService.getAllAssignments();
      print('DEBUG: TrackingScreen loaded ${list.length} assignments');
      if (mounted) {
        setState(() {
          _assignments = list;
          _isLoading = false;
          // Log chi tiết từng nhiệm vụ để gỡ lỗi
          for (var task in _assignments) {
            print('DEBUG Task: ID=${task.id}, Status="${task.status}", isReported=${task.status.trim().toUpperCase() == 'REPORTED'}');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách nhiệm vụ: $e')),
        );
      }
    }
  }

  Future<void> _confirmAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text('Bạn có chắc chắn muốn xác nhận hoàn thành nhiệm vụ của ${assignment.citizenName ?? "người dân"}? \n\nHành động này sẽ giải phóng đội cứu hộ và phương tiện.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _rescueService.updateAssignmentStatus(
        assignment.id, 
        'COMPLETED',
        note: 'Điều phối viên xác nhận hoàn thành',
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận hoàn thành nhiệm vụ')),
        );
        _loadAssignments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phân loại nhiệm vụ
    final activeTasks = _assignments.where((a) => 
      ['ASSIGNED', 'MOVING', 'ARRIVED', 'REPORTED', 'PREPARING', 'RESCUING', 'RETURNING', 'IN_PROGRESS'].contains(a.status.toUpperCase())).toList();
    
    final historyTasks = _assignments.where((a) => 
      ['COMPLETED', 'CANCELLED', 'REJECTED'].contains(a.status.toUpperCase())).toList();

    activeTasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    historyTasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi & Lịch sử'),
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang thực hiện'),
              Tab(text: 'Lịch sử'),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(onPressed: _loadAssignments, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTaskList(activeTasks, 'Không có nhiệm vụ đang thực hiện', true),
                  _buildTaskList(historyTasks, 'Chưa có lịch sử nhiệm vụ', false),
                ],
              ),
      ),
    );
  }

  Widget _buildTaskList(List<Assignment> tasks, String emptyMsg, bool isActive) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildAssignmentCard(task, isActive);
      },
    );
  }

  Widget _buildAssignmentCard(Assignment task, bool isActive) {
    final statusColor = _getStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);
    final isReported = task.status.trim().toUpperCase() == 'REPORTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isReported ? Colors.orange : Colors.grey[200]!, width: isReported ? 2 : 1),
      ),
      elevation: isReported ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  DateFormat('HH:mm dd/MM').format(task.assignedAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.citizenName ?? 'N/A',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.addressText ?? 'Không có địa chỉ',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đội cứu hộ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(task.teamName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phương tiện', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('${task.vehicleType ?? "N/A"} (${task.licensePlate ?? "N/A"})', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            if (task.rescuedCount != null || task.reportNote != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'BÁO CÁO THỰC TẾ',
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.orange.shade900,
                            letterSpacing: 1
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (task.rescuedCount != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• Đã cứu được: ${task.rescuedCount} người',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    if (task.reportNote != null && task.reportNote!.isNotEmpty)
                      Text(
                        '• Ghi chú: ${task.reportNote}',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],
            if (isActive && isReported) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAssignment(task),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('XÁC NHẬN HOÀN THÀNH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), // Xanh lá đậm (Success)
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PREPARING': return Colors.blue;
      case 'MOVING': return Colors.orange;
      case 'ARRIVED': return Colors.purple;
      case 'REPORTED': return Colors.red; // Màu đỏ để gây chú ý cho điều phối viên
      case 'COMPLETED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      case 'ASSIGNED': return Colors.indigo;
      default: return Colors.blueGrey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PREPARING': return 'Đang chuẩn bị';
      case 'MOVING': return 'Đang di chuyển';
      case 'ARRIVED': return 'Đã đến nơi';
      case 'REPORTED': return 'Chờ xác nhận';
      case 'COMPLETED': return 'Đã hoàn thành';
      case 'REJECTED': return 'Bị từ chối';
      case 'CANCELLED': return 'Đã hủy';
      case 'ASSIGNED': return 'Đã phân công';
      default: return status;
    }
  }
}

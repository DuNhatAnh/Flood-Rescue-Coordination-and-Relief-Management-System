import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../models/assignment.dart';
import '../../services/rescue_service.dart';
import '../../services/auth_service.dart';
import '../../utils/staff_theme.dart';
import '../../widgets/mission_stepper.dart';
import 'rescue_report_screen.dart';

class TeamTasksScreen extends StatefulWidget {
  const TeamTasksScreen({Key? key}) : super(key: key);

  @override
  TeamTasksScreenState createState() => TeamTasksScreenState();
}

class TeamTasksScreenState extends State<TeamTasksScreen> {
  final RescueService _rescueService = RescueService();
  late Future<List<Assignment>> _tasksFuture;
  List<LatLng> _routePoints = [];
  
  // Logistics - Phàn 2

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
          
          // Tìm nhiệm vụ đang hoạt động
          Assignment? activeTask;
          try {
            activeTask = tasks.firstWhere(
              (t) => ['ASSIGNED', 'PREPARING', 'IN_PROGRESS', 'MOVING', 'RESCUING', 'RETURNING'].contains(t.status.toUpperCase()),
            );
          } catch (_) {
            activeTask = null;
          }

          if (activeTask != null) {
            return _buildDetailedTaskView(activeTask);
          }

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

  Widget _buildDetailedTaskView(Assignment task) {
    return Row(
      children: [
        // Nửa trái: Bản đồ (SCRUM-61)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300, width: 2)),
            ),
            child: _buildMap(task),
          ),
        ),
        // Nửa phải: Thông tin chi tiết (SCRUM-61)
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(task),
                const SizedBox(height: 16),
                MissionStepper(currentStatus: task.status),
                const SizedBox(height: 16),
                
                // NẾU ĐANG CHUẨN BỊ - HIỆN FORM LOGISTICS (PHẦN 2 NÂNG CẤP)
                if (task.status.toUpperCase() == 'PREPARING')
                  _buildPreparationOptions(task)
                else
                  _buildDetailsCard(task),
                  
                const SizedBox(height: 24),
                _buildActionButtons(task),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- MÀN HÌNH CHUẨN BỊ MỚI (THEO YÊU CẦU) ---
  Widget _buildPreparationOptions(Assignment task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Danh sách hàng được giao
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StaffTheme.border),
            boxShadow: StaffTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VẬT PHẨM ĐƯỢC GIAO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StaffTheme.primaryBlue)),
              const SizedBox(height: 12),
              if (task.assignedItems.isEmpty)
                const Text('Chưa có danh sách vật phẩm cụ thể.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...task.assignedItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.itemName, style: const TextStyle(fontSize: 13)),
                      Text('${item.quantity} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Trạng thái xuất kho
        if (!task.itemsExported) ...[
          const Text('BƯỚC 1: XUẤT KHO HÀNG HÓA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _prepButton(
                  'XUẤT KHO THỦ CÔNG', 
                  Icons.edit_note_rounded, 
                  Colors.white, 
                  StaffTheme.primaryBlue,
                  () => _navigateToWarehouse(task, manual: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _prepButton(
                  'XUẤT KHO NHANH', 
                  Icons.flash_on_rounded, 
                  StaffTheme.primaryBlue, 
                  Colors.white,
                  () => _navigateToWarehouse(task, manual: false),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StaffTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StaffTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: StaffTheme.successGreen),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Đã hoàn thành xuất kho hàng hóa và phương tiện.', 
                    style: TextStyle(color: StaffTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildDetailsCard(task),
      ],
    );
  }

  Widget _prepButton(String label, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: text),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: text,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: StaffTheme.primaryBlue)),
        elevation: 0,
      ),
    );
  }

  void _navigateToWarehouse(Assignment task, {required bool manual}) {
    // Nav tới màn hình kho bãi
    // Trong thực tế, chúng ta sẽ mở Tab Kho bãi hoặc Navigate.
    // Ở đây tôi giả sử màn hình Kho bãi có thể nhận context mission.
    Navigator.pushNamed(context, '/warehouse', arguments: {
      'missionContext': task,
      'mode': manual ? 'MANUAL' : 'QUICK'
    }).then((_) => refreshTasks());
  }

  Widget _buildHeader(Assignment task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHI TIẾT NHIỆM VỤ', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: StaffTheme.textLight, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('#${task.id.substring(0, 8).toUpperCase()}', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(task.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(task.status).withOpacity(0.5)),
          ),
          child: Text(
            _getStatusLabel(task.status),
            style: TextStyle(color: _getStatusColor(task.status), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Assignment task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: StaffTheme.softShadow,
        border: Border.all(color: StaffTheme.border),
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.person, 'Người cần cứu', task.citizenName ?? 'N/A'),
          const Divider(height: 30),
          _buildDetailItem(Icons.location_on, 'Địa chỉ', task.addressText ?? 'N/A', color: StaffTheme.errorRed),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.people, 'Số người', '${task.numberOfPeople ?? 0} người')),
              Expanded(child: _buildDetailItem(Icons.priority_high, 'Khẩn cấp', task.urgencyLevel ?? 'BÌNH THƯỜNG', 
                  color: task.urgencyLevel == 'HIGH' ? StaffTheme.errorRed : StaffTheme.warningOrange)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.description ?? 'Không có mô tả chi tiết.',
              style: const TextStyle(fontSize: 14, height: 1.5, color: StaffTheme.textMedium),
            ),
          ),
          if (task.missionItems.isNotEmpty) ...[
            const Divider(height: 30),
            const Text('VẬT PHẨM MANG THEO', style: TextStyle(fontSize: 11, color: StaffTheme.textLight, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...task.missionItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.itemName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? StaffTheme.primaryBlue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: StaffTheme.textLight, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: StaffTheme.textDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(Assignment task) {
    final status = task.status.toUpperCase();
    
    if (status == 'ASSIGNED') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleStatusUpdate(task, 'PREPARING', 'Đã chấp nhận nhiệm vụ. Hãy chuẩn bị hàng hóa!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CHẤP NHẬN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleReject(task),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: StaffTheme.errorRed, width: 1.5),
                foregroundColor: StaffTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('TỪ CHỐI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      );
    }

    if (status == 'PREPARING') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: task.itemsExported ? () {
                _handleStatusUpdate(
                  task, 
                  'MOVING', 
                  'Đã chuẩn bị xong và bắt đầu di chuyển!',
                );
              } : null, // Chỉ cho nhấn khi đã xuất hàng
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: const Text('XÁC NHẬN CHUẨN BỊ XONG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: task.itemsExported ? StaffTheme.successGreen : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'MOVING') {
      return _buildSingleActionButton(
        task, 'RESCUING', 'ĐÃ ĐẾN HIỆN TRƯỜNG', StaffTheme.warningOrange, 'Đã đến nơi. Hãy thực hiện cứu hộ!'
      );
    }

    if (status == 'RESCUING') {
      return _buildSingleActionButton(
        task, 'RETURNING', 'ĐƯA NẠN NHÂN VỀ AN TOÀN', StaffTheme.successGreen, 'Đang đưa nạn nhân về vùng an toàn.'
      );
    }

    if (status == 'RETURNING' || status == 'IN_PROGRESS') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RescueReportScreen(assignmentId: task.id)),
          ).then((_) => refreshTasks());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: StaffTheme.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.assignment_turned_in_rounded),
        label: const Text('GỬI BÁO CÁO KẾT THÚC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSingleActionButton(Assignment task, String nextStatus, String label, Color color, String message) {
    return ElevatedButton(
      onPressed: () => _handleStatusUpdate(task, nextStatus, message),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
    );
  }

  Future<void> _handleStatusUpdate(Assignment task, String nextStatus, String snackMessage, {List<Map<String, dynamic>>? items}) async {
    final success = await _rescueService.updateAssignmentStatus(
      task.id, 
      nextStatus,
      userId: AuthService.currentUser?.id,
      items: items,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackMessage)));
        refreshTasks();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi cập nhật trạng thái.')));
      }
    }
  }

  Future<void> _loadRoute(LatLng destination) async {
    // Vị trí giả lập của đội (Cầu Rồng, Đà Nẵng)
    final teamLocation = const LatLng(16.0611, 108.2233);
    
    if (_routePoints.isEmpty || (_routePoints.isNotEmpty && _routePoints.last != destination)) {
      final points = await _rescueService.getRoutePoints(teamLocation, destination);
      if (mounted) {
        setState(() {
          _routePoints = points;
        });
      }
    }
  }

  Widget _buildMap(Assignment task) {
    final destination = LatLng(task.locationLat ?? 16.0, task.locationLng ?? 108.0);
    final teamLocation = const LatLng(16.0611, 108.2233);
    
    // Tự động load đường đi nếu chưa có
    _loadRoute(destination);
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: destination,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'vn.rescue.core',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: StaffTheme.primaryBlue,
                strokeWidth: 4,
                isDotted: false,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Marker Đội cứu hộ
            Marker(
              point: teamLocation,
              width: 40,
              height: 40,
              child: const Icon(Icons.directions_boat_rounded, color: StaffTheme.primaryBlue, size: 30),
            ),
            // Marker Nạn nhân
            Marker(
              point: destination,
              width: 80,
              height: 80,
              child: const Icon(Icons.location_on, color: StaffTheme.errorRed, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  // Removed _handleAccept as it's merged into _handleStatusUpdate

  Future<void> _handleReject(Assignment task) async {
    final TextEditingController reasonController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối nhiệm vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối chính đáng:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'VD: Hỏng xuồng máy, hết xăng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('XÁC NHẬN TỪ CHỐI'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _rescueService.updateAssignmentStatus(
        task.id, 'REJECTED', note: reasonController.text.trim()
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối nhiệm vụ.'))
          );
          refreshTasks();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi gửi yêu cầu từ chối.'))
          );
        }
      }
    }
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StaffTheme.warningOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_late_rounded, color: StaffTheme.warningOrange.withValues(alpha: 0.7), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('NHIỆM VỤ #${task.id.length > 4 ? task.id.substring(0, 4).toUpperCase() : task.id.toUpperCase()}', style: StaffTheme.cardTitle),
                          Text(timeStr, style: const TextStyle(color: StaffTheme.textLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildIconText(Icons.location_on_rounded, task.addressText ?? 'Địa chỉ không xác định', StaffTheme.errorRed),
                      const SizedBox(height: 4),
                      _buildIconText(Icons.directions_boat_rounded, task.licensePlate != null ? 'Phương tiện: ${task.licensePlate}' : 'Chưa gán phương tiện', StaffTheme.primaryBlue),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(task.status),
                          style: TextStyle(color: _getStatusColor(task.status), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
                        MaterialPageRoute(builder: (context) => RescueReportScreen(assignmentId: task.id)),
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
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED': return StaffTheme.primaryBlue;
      case 'PREPARING': return StaffTheme.warningOrange;
      case 'RESCUING': return StaffTheme.errorRed;
      case 'RETURNING': return StaffTheme.successGreen;
      case 'COMPLETED': return StaffTheme.successGreen;
      case 'REJECTED':
      case 'CANCELLED': return StaffTheme.errorRed;
      default: return StaffTheme.primaryBlue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED': return 'ĐÃ PHÂN CÔNG';
      case 'PREPARING': return 'ĐANG CHUẨN BỊ';
      case 'RESCUING': return 'ĐANG CỨU HỘ';
      case 'RETURNING': return 'ĐANG QUAY VỀ';
      case 'IN_PROGRESS': return 'ĐANG THỰC HIỆN';
      case 'COMPLETED': return 'ĐÃ HOÀN THÀNH';
      case 'REJECTED': return 'BỊ TỪ CHỐI';
      case 'CANCELLED': return 'ĐÃ HỦY';
      default: return status.toUpperCase();
    }
  }
}

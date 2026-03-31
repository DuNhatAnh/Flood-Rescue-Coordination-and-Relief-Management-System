import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/distribution.dart';
import '../../services/distribution_service.dart';
import '../../services/report_service.dart';
import '../../utils/staff_theme.dart';

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({Key? key}) : super(key: key);

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  final DistributionService _distService = DistributionService();
  final ReportService _reportService = ReportService();
  
  List<Distribution> _history = [];
  bool _isLoading = true;
  
  // Biến lưu trữ số liệu thực tế từ API
  int _completedTasks = 0;
  int _activeTasks = 0;
  int _pendingTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Tải dữ liệu thực tế từ Backend
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Chạy song song các API để tối ưu tốc độ
      final results = await Future.wait([
        _reportService.getStaffDashboard(),
        _distService.getHistory(),
      ]);

      // results[0] là Map<String, dynamic> do ReportService trả về trực tiếp phần 'data'
      final dynamic responseData = results[0];
      final List<Distribution> historyData = (results[1] as List<Distribution>?) ?? [];

      if (mounted) {
        setState(() {
          // XỬ LÝ DỮ LIỆU DASHBOARD VỚI ÉP KIỂU AN TOÀN
          if (responseData != null && responseData is Map) {
            // Sử dụng int.tryParse kết hợp toString() để tránh lỗi subtype (double/int/num)
            _completedTasks = int.tryParse(responseData['completedTasks']?.toString() ?? '0') ?? 0;
            _activeTasks = int.tryParse(responseData['activeTasks']?.toString() ?? '0') ?? 0;
            _pendingTasks = int.tryParse(responseData['pendingTasks']?.toString() ?? '0') ?? 0;
            
            debugPrint("📊 UI CẬP NHẬT THÀNH CÔNG:");
            debugPrint("- Hoàn thành: $_completedTasks");
            debugPrint("- Đang làm (Assigned): $_activeTasks");
            debugPrint("- Chờ xử lý: $_pendingTasks");
          } else {
            debugPrint("⚠️ Cảnh báo: API Dashboard không trả về dữ liệu Map hợp lệ.");
          }
          
          // XỬ LÝ DỮ LIỆU LỊCH SỬ
          _history = historyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Lỗi nghiêm trọng tại StaffReportScreen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: const Text('THỐNG KÊ & LỊCH SỬ', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(), // Đảm bảo luôn vuốt được để refresh
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('TỔNG QUAN NHIỆM VỤ'),
                  const SizedBox(height: 15),
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('LỊCH SỬ BIẾN ĐỘNG NGUỒN LỰC'),
                  const SizedBox(height: 15),
                  _history.isEmpty 
                      ? _buildEmptyHistory()
                      : _buildHistoryList(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('HOÀN THÀNH', _completedTasks.toString(), Colors.green, Icons.check_circle_outline)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard('ĐANG LÀM', _activeTasks.toString(), StaffTheme.primaryBlue, Icons.pending_actions_rounded)),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatCard('CHƯA XỬ LÝ', _pendingTasks.toString(), Colors.orange, Icons.warning_amber_rounded, isWide: true),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, {bool isWide = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StaffTheme.softShadow,
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: StaffTheme.textLight, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StaffTheme.textMedium, letterSpacing: 0.5));
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final dist = _history[index];
        final isExport = dist.type == 'EXPORT';
        final dateStr = DateFormat('dd/MM HH:mm').format(dist.distributedAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: (isExport ? StaffTheme.primaryBlue : Colors.indigo).withOpacity(0.1),
              child: Icon(
                isExport ? Icons.outbox_rounded : Icons.local_shipping_rounded,
                color: isExport ? StaffTheme.primaryBlue : Colors.indigo,
              ),
            ),
            title: Text(
              isExport ? 'Xuất cứu trợ #${_formatId(dist.id)}' : 'Điều chuyển kho #${_formatId(dist.id)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(dist.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dist.status,
                style: TextStyle(color: _getStatusColor(dist.status), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () => _showHistoryDetail(dist),
          ),
        );
      },
    );
  }

  String _formatId(String? id) {
    if (id == null || id.length < 4) return "....";
    return id.substring(id.length - 4).toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'IN_TRANSIT': return Colors.blue;
      case 'PENDING': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('Chưa có lịch sử biến động nào', style: TextStyle(color: StaffTheme.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showHistoryDetail(Distribution dist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Chi tiết giao dịch', style: StaffTheme.titleLarge),
            const Divider(height: 30),
            _buildDetailRow('Mã vận đơn:', dist.id ?? 'N/A'),
            _buildDetailRow('Ngày giờ:', DateFormat('dd/MM/yyyy HH:mm').format(dist.distributedAt)),
            _buildDetailRow('Loại hình:', dist.type == 'EXPORT' ? 'Xuất cứu trợ' : 'Điều chuyển kho'),
            _buildDetailRow('Trạng thái:', dist.status),
            const SizedBox(height: 20),
            const Text('DANH SÁCH VẬT PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            if (dist.items.isNotEmpty)
              ...dist.items.map((item) => _buildDetailItem(item.itemName, "${item.quantity} ${item.unit}")).toList()
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("Không có thông tin vật phẩm", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: StaffTheme.textLight)),
          const SizedBox(width: 10),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String name, String qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StaffTheme.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(qty, style: const TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
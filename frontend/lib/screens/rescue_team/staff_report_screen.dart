import 'package:flutter/material.dart';
import '../../models/distribution.dart';
import '../../services/distribution_service.dart';
import '../../services/rescue_service.dart';
import '../../utils/staff_theme.dart';
import 'package:intl/intl.dart';

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({Key? key}) : super(key: key);

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  final DistributionService _distService = DistributionService();
  final RescueService _rescueService = RescueService();
  
  List<Distribution> _history = [];
  bool _isLoading = true;
  
  // Fake stats for Demo
  final int _completedTasks = 12;
  final int _activeTasks = 3;
  final int _pendingTasks = 5;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _distService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: const Text('THỐNG KÊ & LỊCH SỬ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 30),
              _buildSectionTitle('LỊCH SỬ BIẾN ĐỘNG NGUỒN LỰC'),
              const SizedBox(height: 15),
              _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty 
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
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: StaffTheme.textMedium));
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
              isExport ? 'Xuất cứu trợ #${(dist.id ?? "....").substring((dist.id?.length ?? 4) - 4)}' : 'Điều chuyển kho #${(dist.id ?? "....").substring((dist.id?.length ?? 4) - 4)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
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
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
            onTap: () => _showHistoryDetail(dist),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'IN_TRANSIT': return Colors.blue;
      default: return Colors.orange;
    }
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          const Text('Chưa có dữ liệu lịch sử', style: TextStyle(color: StaffTheme.textLight)),
        ],
      ),
    );
  }

  void _showHistoryDetail(Distribution dist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chi tiết giao dịch', style: StaffTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 30),
              _buildDetailRow('Mã vận đơn:', dist.id ?? 'N/A'),
              _buildDetailRow('Ngày giờ:', DateFormat('dd/MM/yyyy HH:mm').format(dist.distributedAt)),
              _buildDetailRow('Loại hình:', dist.type == 'EXPORT' ? 'Xuất cứu trợ' : 'Điều chuyển kho'),
              _buildDetailRow('Trạng thái:', dist.status),
              const SizedBox(height: 30),
              const Text('DANH SÁCH HÀNG HÓA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              // Dummy items for transaction detail
              _buildDetailItem('Mì tôm Hảo Hảo', '20 thùng'),
              _buildDetailItem('Nước suối Aquafina', '50 lốc'),
              _buildDetailItem('Áo phao cứu sinh', '10 cái'),
            ],
          ),
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
          Flexible(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String name, String qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StaffTheme.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(qty, style: const TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

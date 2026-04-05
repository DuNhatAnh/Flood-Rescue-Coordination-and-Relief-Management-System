import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Thư viện biểu đồ
import '../../models/distribution.dart';
import '../../models/dashboard_stats_model.dart';
import '../../services/distribution_service.dart';
import '../../services/report_service.dart';
import '../../utils/staff_theme.dart';

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({Key? key}) : super(key: key);

  @override
  State<StaffReportScreen> createState() => StaffReportScreenState();
}

class StaffReportScreenState extends State<StaffReportScreen> {
  final DistributionService _distService = DistributionService();
  final ReportService _reportService = ReportService();

  List<Distribution> _history = [];
  bool _isLoading = true;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _reportService.getStaffDashboard(),
        _distService.getHistory(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as DashboardStats?;
          _history = (results[1] as List<Distribution>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Lỗi StaffReportScreen: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: const Text('THỐNG KÊ CHI TIẾT',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: refreshData)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('TRẠNG THÁI NHIỆM VỤ'),
                    const SizedBox(height: 15),
                    _buildPieChartCard(), // Biểu đồ tròn

                    const SizedBox(height: 30),
                    _buildSectionTitle('THỐNG KÊ VẬT PHẨM TỒN KHO'),
                    const SizedBox(height: 15),
                    _buildBarChartCard(), // Biểu đồ cột mới thêm

                    const SizedBox(height: 30),
                    _buildSectionTitle('CON SỐ TỔNG QUAN'),
                    const SizedBox(height: 15),
                    _buildStatsGrid(),

                    if (_stats != null && _stats!.lowStockAlerts.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      _buildSectionTitle('CẢNH BÁO TỒN KHO THẤP'),
                      const SizedBox(height: 15),
                      _buildLowStockAlerts(),
                    ],

                    const SizedBox(height: 30),
                    _buildSectionTitle('LỊCH SỬ BIẾN ĐỘNG'),
                    const SizedBox(height: 15),
                    _history.isEmpty ? _buildEmptyHistory() : _buildHistoryList(),
                  ],
                ),
              ),
      ),
    );
  }

  /// 📊 BIỂU ĐỒ TRÒN: Tỷ lệ nhiệm vụ
  Widget _buildPieChartCard() {
    if (_stats == null) return const SizedBox.shrink();
    int total = _stats!.completedTasks + _stats!.activeTasks + _stats!.pendingTasks;
    if (total == 0) return _buildNoDataCard();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: StaffTheme.softShadow),
      child: Row(
        children: [
          SizedBox(
            height: 120, width: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(value: _stats!.completedTasks.toDouble(), color: Colors.green, title: '', radius: 40),
                  PieChartSectionData(value: _stats!.activeTasks.toDouble(), color: StaffTheme.primaryBlue, title: '', radius: 40),
                  PieChartSectionData(value: _stats!.pendingTasks.toDouble(), color: Colors.orange, title: '', radius: 40),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(Colors.green, "Xong: ${_stats!.completedTasks}"),
                _buildLegend(StaffTheme.primaryBlue, "Làm: ${_stats!.activeTasks}"),
                _buildLegend(Colors.orange, "Chờ: ${_stats!.pendingTasks}"),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 📊 BIỂU ĐỒ CỘT: Thống kê vật phẩm (Sử dụng dữ liệu tồn kho thấp làm mẫu)
  Widget _buildBarChartCard() {
    if (_stats == null || _stats!.lowStockAlerts.isEmpty) return _buildNoDataCard();

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(15, 25, 15, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: StaffTheme.softShadow),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _stats!.lowStockAlerts.map((e) => e.quantity).reduce((a, b) => a > b ? a : b).toDouble() + 50,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _stats!.lowStockAlerts.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_stats!.lowStockAlerts[index].itemName.substring(0, 3), 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _stats!.lowStockAlerts.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.quantity.toDouble(),
                  color: StaffTheme.primaryBlue,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.grey.shade100),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: StaffTheme.textMedium, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text("Không có dữ liệu hiển thị", style: TextStyle(color: Colors.grey))),
    );
  }

  /// --- Các Widget cũ được giữ nguyên và tối ưu hóa ---

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('HOÀN THÀNH', (_stats?.completedTasks ?? 0).toString(), Colors.green, Icons.check_circle_outline)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard('ĐANG LÀM', (_stats?.activeTasks ?? 0).toString(), StaffTheme.primaryBlue, Icons.pending_actions_rounded)),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatCard('CHƯA XỬ LÝ', (_stats?.pendingTasks ?? 0).toString(), Colors.orange, Icons.warning_amber_rounded, isWide: true),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: StaffTheme.softShadow,
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: StaffTheme.textLight, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlerts() {
    return Column(
      children: _stats!.lowStockAlerts.map((alert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Còn: ${alert.quantity} ${alert.unit}", style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final dist = _history[index];
        final isExport = dist.type == 'EXPORT';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isExport ? StaffTheme.primaryBlue : Colors.indigo).withOpacity(0.1),
              child: Icon(isExport ? Icons.outbox_rounded : Icons.local_shipping_rounded, color: isExport ? StaffTheme.primaryBlue : Colors.indigo),
            ),
            title: Text(isExport ? 'Xuất cứu trợ #${_formatId(dist.id)}' : 'Điều chuyển #${_formatId(dist.id)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(DateFormat('dd/MM HH:mm').format(dist.distributedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: _buildStatusBadge(dist.status),
            onTap: () => _showHistoryDetail(dist),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatId(String? id) => (id == null || id.length < 4) ? "...." : id.substring(id.length - 4).toUpperCase();

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'IN_TRANSIT': return Colors.blue;
      case 'PENDING': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StaffTheme.textMedium, letterSpacing: 0.5));
  }

  Widget _buildEmptyHistory() => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Chưa có lịch sử')));

  void _showHistoryDetail(Distribution dist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
            _buildDetailRow('Loại hình:', dist.type == 'EXPORT' ? 'Xuất cứu trợ' : 'Điều chuyển kho'),
            _buildDetailRow('Trạng thái:', dist.status),
            const SizedBox(height: 20),
            const Text('DANH SÁCH VẬT PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            ...dist.items.map((item) => _buildDetailItem(item.itemName, "${item.quantity} ${item.unit}")).toList(),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/distribution.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/vehicle.dart';
import '../../services/distribution_service.dart';
import '../../services/report_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/staff_theme.dart';

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({Key? key}) : super(key: key);

  @override
  State<StaffReportScreen> createState() => StaffReportScreenState();
}

class StaffReportScreenState extends State<StaffReportScreen> {
  final DistributionService _distService = DistributionService();
  final ReportService _reportService = ReportService();
  final VehicleService _vehicleService = VehicleService();

  List<Distribution> _history = [];
  List<Vehicle> _vehicles = []; // Danh sách phương tiện chi tiết
  bool _isLoading = true;
  DashboardStats? _stats;
  
  // Dữ liệu thống kê phương tiện
  Map<String, dynamic> _vehicleStats = {
    'total': 0, 'available': 0, 'in_use': 0, 'maintenance': 0
  };

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Gọi đồng thời 4 API: Dashboard, Lịch sử, Thống kê xe và Danh sách xe
      final results = await Future.wait([
        _reportService.getStaffDashboard(),
        _distService.getHistory(),
        _vehicleService.getVehicleStatistics(),
        _vehicleService.getAllVehicles(size: 100), // Lấy danh sách để liệt kê
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as DashboardStats?;
          _history = (results[1] as List<Distribution>?) ?? [];
          _vehicleStats = results[2] as Map<String, dynamic>;
          
          // Xử lý dữ liệu danh sách xe từ kết quả thứ 4
          final vehicleData = results[3] as Map<String, dynamic>;
          final List content = vehicleData['content'] ?? [];
          _vehicles = content.map((e) => Vehicle.fromJson(e)).toList();
          
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
        color: StaffTheme.primaryBlue,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('TRẠNG THÁI NHIỆM VỤ'),
                    const SizedBox(height: 15),
                    _buildPieChartCard(), 

                    const SizedBox(height: 30),
                    _buildSectionTitle('TRẠNG THÁI PHƯƠNG TIỆN'),
                    const SizedBox(height: 15),
                    _buildVehiclePieChart(),

                    const SizedBox(height: 30),
                    _buildSectionTitle('DANH SÁCH PHƯƠNG TIỆN CHI TIẾT'),
                    const SizedBox(height: 15),
                    _buildVehicleList(),

                    const SizedBox(height: 30),
                    _buildSectionTitle('THỐNG KÊ VẬT PHẨM TỒN KHO'),
                    const SizedBox(height: 15),
                    _buildBarChartCard(), 

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

  /// 🚗 DANH SÁCH PHƯƠNG TIỆN (Mới thêm)
  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) return _buildNoDataCard();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        final statusColor = _getVehicleStatusColor(v.status);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: StaffTheme.softShadow,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(_getVehicleIcon(v.vehicleType), color: statusColor, size: 20),
            ),
            title: Text(v.licensePlate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${v.vehicleType} • ${v.currentLocation ?? 'Kho trung tâm'}", style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(_translateVehicleStatus(v.status), 
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  /// 🚗 BIỂU ĐỒ TRÒN PHƯƠNG TIỆN
  Widget _buildVehiclePieChart() {
    int available = _vehicleStats['available'] ?? 0;
    int inUse = _vehicleStats['in_use'] ?? 0;
    int maintenance = _vehicleStats['maintenance'] ?? 0;
    int total = available + inUse + maintenance;

    if (total == 0) return _buildNoDataCard();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: StaffTheme.softShadow),
      child: Row(
        children: [
          SizedBox(
            height: 100, width: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(value: available.toDouble(), color: Colors.green, title: '', radius: 30),
                  PieChartSectionData(value: inUse.toDouble(), color: StaffTheme.primaryBlue, title: '', radius: 30),
                  PieChartSectionData(value: maintenance.toDouble(), color: Colors.orange, title: '', radius: 30),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(Colors.green, "Sẵn sàng: $available"),
                _buildLegend(StaffTheme.primaryBlue, "Đang dùng: $inUse"),
                _buildLegend(Colors.orange, "Bảo trì: $maintenance"),
                const Divider(),
                Text("Tổng cộng: $total xe", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
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
            height: 100, width: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(value: _stats!.completedTasks.toDouble(), color: Colors.green, title: '', radius: 30),
                  PieChartSectionData(value: _stats!.activeTasks.toDouble(), color: StaffTheme.primaryBlue, title: '', radius: 30),
                  PieChartSectionData(value: _stats!.pendingTasks.toDouble(), color: Colors.orange, title: '', radius: 30),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(Colors.green, "Hoàn thành: ${_stats!.completedTasks}"),
                _buildLegend(StaffTheme.primaryBlue, "Đang xử lý: ${_stats!.activeTasks}"),
                _buildLegend(Colors.orange, "Đang chờ: ${_stats!.pendingTasks}"),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 📊 BIỂU ĐỒ CỘT: Thống kê vật phẩm
  Widget _buildBarChartCard() {
    if (_stats == null || _stats!.lowStockAlerts.isEmpty) return _buildNoDataCard();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(15, 25, 15, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: StaffTheme.softShadow),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _stats!.lowStockAlerts.map((e) => e.quantity).reduce((a, b) => a > b ? a : b).toDouble() + 10,
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
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  IconData _getVehicleIcon(String type) {
    String t = type.toLowerCase();
    if (t.contains('tải')) return Icons.local_shipping;
    if (t.contains('cano') || t.contains('thuyền')) return Icons.directions_boat;
    return Icons.directions_car;
  }

  Color _getVehicleStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return Colors.green;
      case 'IN_USE': return StaffTheme.primaryBlue;
      case 'MAINTENANCE': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _translateVehicleStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return 'Sẵn sàng';
      case 'IN_USE': return 'Đang dùng';
      case 'MAINTENANCE': return 'Bảo trì';
      default: return 'Khác';
    }
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: StaffTheme.textMedium)),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: StaffTheme.softShadow),
      child: const Center(child: Text("Không có dữ liệu hiển thị", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('NHIỆM VỤ XONG', (_stats?.completedTasks ?? 0).toString(), Colors.green, Icons.check_circle_outline)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard('TỔNG XE', (_vehicleStats['total'] ?? 0).toString(), Colors.blue, Icons.directions_car)),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatCard('NHIỆM VỤ ĐANG CHỜ', (_stats?.pendingTasks ?? 0).toString(), Colors.orange, Icons.warning_amber_rounded, isWide: true),
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
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(fontSize: 9, color: StaffTheme.textLight, fontWeight: FontWeight.bold)),
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
                    Text("Còn lại: ${alert.quantity} ${alert.unit}", style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: StaffTheme.softShadow),
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
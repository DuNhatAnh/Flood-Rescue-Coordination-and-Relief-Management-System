import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/vehicle_service.dart';
import '../../models/vehicle.dart'; 
import '../../utils/staff_theme.dart';

class StaffVehicleManagementScreen extends StatefulWidget {
  const StaffVehicleManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffVehicleManagementScreen> createState() => StaffVehicleManagementScreenState();
}

class StaffVehicleManagementScreenState extends State<StaffVehicleManagementScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = true;
  List<Vehicle> _vehicles = []; 
  
  // Khởi tạo stats mặc định
  Map<String, dynamic> _stats = {
    'total': 0,
    'available': 0,
    'in_use': 0,
    'maintenance': 0
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
      // Gọi đồng thời cả 2 API để tối ưu tốc độ
      final results = await Future.wait([
        _vehicleService.getAllVehicles(size: 100),
        _vehicleService.getVehicleStatistics(),
      ]);

      final vehicleData = results[0] as Map<String, dynamic>;
      final statsData = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          // Xử lý danh sách xe
          final List content = vehicleData['content'] ?? [];
          _vehicles = content.map((e) => Vehicle.fromJson(e)).toList();
          
          // Logic dự phòng: Nếu API thống kê lỗi/trống, tự tính toán từ danh sách
          if ((statsData['total'] == 0 || statsData.isEmpty) && _vehicles.isNotEmpty) {
            _stats = {
              'total': _vehicles.length,
              'available': _vehicles.where((v) => v.status.toUpperCase() == 'AVAILABLE').length,
              'in_use': _vehicles.where((v) => v.status.toUpperCase() == 'IN_USE').length,
              'maintenance': _vehicles.where((v) => v.status.toUpperCase() == 'MAINTENANCE').length,
            };
          } else {
            _stats = statsData;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu phương tiện: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return Colors.green.shade600;
      case 'IN_USE': return StaffTheme.primaryBlue;
      case 'MAINTENANCE': return Colors.orange.shade700;
      default: return Colors.grey;
    }
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return 'Sẵn sàng';
      case 'IN_USE': return 'Đang dùng';
      case 'MAINTENANCE': return 'Bảo trì';
      default: return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshData,
      color: StaffTheme.primaryBlue,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStats(),
                const SizedBox(height: 20),
                _buildChartSection(), // Phần biểu đồ đã được phóng to
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("DANH SÁCH PHƯƠNG TIỆN", 
                      style: StaffTheme.titleLarge.copyWith(color: StaffTheme.textDark, fontSize: 16)),
                    _buildVehicleCountBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVehicleList(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderStats() {
    return Row(
      children: [
        _statCard("TỔNG CỘNG", (_stats['total'] ?? 0).toString(), Icons.directions_car, Colors.blue),
        const SizedBox(width: 12),
        _statCard("SẴN SÀNG", (_stats['available'] ?? 0).toString(), Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    int available = _stats['available'] ?? 0;
    int inUse = _stats['in_use'] ?? 0;
    int maintenance = _stats['maintenance'] ?? 0;
    bool hasData = (available + inUse + maintenance) > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          const Text("TỈ LỆ TRẠNG THÁI", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 25),
          SizedBox(
            height: 250, // ĐÃ TĂNG: Từ 180 lên 250
            child: hasData ? PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60, // ĐÃ TĂNG: Tạo khoảng trống giữa lớn hơn
                sections: [
                  if (available > 0) _chartSection(available.toDouble(), Colors.green.shade500, "Rảnh"),
                  if (inUse > 0) _chartSection(inUse.toDouble(), StaffTheme.primaryBlue, "Bận"),
                  if (maintenance > 0) _chartSection(maintenance.toDouble(), Colors.orange.shade600, "Bảo trì"),
                ],
              ),
            ) : const Center(child: Text("Chưa có dữ liệu phân loại", style: TextStyle(color: Colors.grey))),
          ),
          if (hasData) ...[
            const SizedBox(height: 25),
            _buildLegend(),
          ]
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _legendItem("Rảnh", Colors.green.shade500),
        _legendItem("Bận", StaffTheme.primaryBlue),
        _legendItem("Bảo trì", Colors.orange.shade600),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  PieChartSectionData _chartSection(double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '${value.toInt()}',
      radius: 65, // ĐÃ TĂNG: Giúp miếng bánh dày hơn
      titleStyle: const TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.bold, 
        color: Colors.white,
        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text("Không tìm thấy phương tiện nào"),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        final statusColor = _getStatusColor(v.status);
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(_getVehicleIcon(v.vehicleType), color: statusColor, size: 22),
            ),
            title: Text(v.licensePlate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Loại: ${v.vehicleType}\nVị trí: ${v.currentLocation ?? 'Tại kho'}", 
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_translateStatus(v.status), 
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () => _showVehicleDetail(v),
          ),
        );
      },
    );
  }

  IconData _getVehicleIcon(String type) {
    String t = type.toLowerCase();
    if (t.contains('tải')) return Icons.local_shipping;
    if (t.contains('cano') || t.contains('xuồng')) return Icons.directions_boat;
    return Icons.directions_car;
  }

  Widget _buildVehicleCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: StaffTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text("${_vehicles.length} xe", 
        style: const TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _showVehicleDetail(Vehicle v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Chi tiết phương tiện", style: StaffTheme.titleLarge.copyWith(fontSize: 20)),
            const SizedBox(height: 10),
            const Divider(),
            _detailRow("Biển số xe", v.licensePlate),
            _detailRow("Loại phương tiện", v.vehicleType),
            _detailRow("Trạng thái", _translateStatus(v.status)),
            _detailRow("Vị trí hiện tại", v.currentLocation ?? "Tại kho"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StaffTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("ĐÓNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
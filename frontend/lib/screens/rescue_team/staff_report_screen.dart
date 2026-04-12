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

  bool _isLoading = true;
  DashboardStats? _stats;
  
  // Dữ liệu mới
  List<dynamic> _warehouseTrend = [];
  Map<String, dynamic> _extendedStats = {};
  List<dynamic> _rescueHistory = [];
  List<dynamic> _exportHistory = [];
  List<dynamic> _importHistory = [];
  List<dynamic> _vehicleHistory = [];
  
  String _trendPeriod = 'week';
  int _warehouseTab = 0; // 0: Xuất, 1: Nhập

  // Lọc theo vật phẩm
  List<dynamic> _availableItems = [];
  String? _selectedItemId;
  String _currentUnit = 'đơn vị';

  final ScrollController _rescueScrollController = ScrollController();
  final ScrollController _exportScrollController = ScrollController();
  final ScrollController _importScrollController = ScrollController();
  final ScrollController _vehicleScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _rescueScrollController.dispose();
    _exportScrollController.dispose();
    _importScrollController.dispose();
    _vehicleScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _reportService.getStaffDashboard(),
        _reportService.getAvailableItems(),
        _reportService.getWarehouseTrend(_trendPeriod),
        _reportService.getExtendedStats(),
        _reportService.getRescueHistory(),
        _reportService.getWarehouseHistory('EXPORT'),
        _reportService.getWarehouseHistory('IMPORT'),
        _reportService.getVehicleHistory(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as DashboardStats?;
          _availableItems = results[1] as List<dynamic>;
          final trendResult = results[2] as Map<String, dynamic>;
          _warehouseTrend = trendResult['trend'] ?? [];
          _currentUnit = trendResult['unit'] ?? 'đơn vị';
          _extendedStats = results[3] as Map<String, dynamic>;
          _rescueHistory = results[4] as List<dynamic>;
          _exportHistory = results[5] as List<dynamic>;
          _importHistory = results[6] as List<dynamic>;
          _vehicleHistory = results[7] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Lỗi StaffReportScreen: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTrendData() async {
    try {
      final result = await _reportService.getWarehouseTrend(_trendPeriod, itemId: _selectedItemId);
      if (mounted) {
        setState(() {
          _warehouseTrend = result['trend'] ?? [];
          _currentUnit = result['unit'] ?? 'đơn vị';
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải xu hướng kho: $e");
    }
  }

  Future<void> refreshData() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: StaffTheme.background,
      body: RefreshIndicator(
        onRefresh: refreshData,
        color: StaffTheme.primaryBlue,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHẦN 1: TỔNG QUAN & BIỂU ĐỒ (Đã có card riêng bên trong)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildWarehouseTrendCard()),
                const SizedBox(width: 15),
                Expanded(flex: 2, child: _buildMissionSummaryCard()),
              ],
            ),

            const SizedBox(height: 25),

            // PHẦN 2: LỊCH SỬ CỨU HỘ
            _buildGroupedSection(
              title: 'LỊCH SỬ CỨU HỘ',
              icon: Icons.health_and_safety_rounded,
              iconColor: Colors.red,
              child: _buildRescueHistoryList(),
            ),

                    const SizedBox(height: 25),

                    // PHẦN 3: LỊCH SỬ XUẤT NHẬP HÀNG HÓA
                    _buildGroupedSection(
                      title: 'LỊCH SỬ XUẤT NHẬP HÀNG HÓA',
                      icon: Icons.inventory_2_rounded,
                      iconColor: StaffTheme.primaryBlue,
                      child: _buildWarehouseHistorySection(),
                    ),

                    const SizedBox(height: 25),

                    // PHẦN 4: LỊCH SỬ SỬ DỤNG PHƯƠNG TIỆN
                    _buildGroupedSection(
                      title: 'LỊCH SỬ SỬ DỤNG PHƯƠNG TIỆN',
                      icon: Icons.directions_boat_filled_rounded,
                      iconColor: Colors.indigo,
                      child: _buildVehicleUsageHistoryList(),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  /// 📊 BIỂU ĐỒ ĐƯỜNG: XU HƯỚNG KHO BÃI (3/5)
  Widget _buildWarehouseTrendCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: StaffTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("BIỂU ĐỒ XUẤT NHẬP HÀNG HÓA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  // Dropdown chọn vật phẩm
                  Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedItemId,
                        hint: const Text("Tất cả vật phẩm", style: TextStyle(fontSize: 12)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Tất cả hàng hóa", style: TextStyle(fontSize: 12))),
                          ..._availableItems.map((item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text(item['name'], style: const TextStyle(fontSize: 12)),
                          )).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedItemId = val;
                          });
                          _fetchTrendData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Nút đổi thời gian
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    _buildTimeButton('Tuần', 'week'),
                    _buildTimeButton('Tháng', 'month'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _warehouseTrend.isEmpty 
              ? const Center(child: Text("Đang tải dữ liệu..."))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 5000,
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < _warehouseTrend.length && index % (_trendPeriod == 'week' ? 1 : 5) == 0) {
                              String date = _warehouseTrend[index]['date'].toString();
                              return Text(date.substring(5), style: const TextStyle(fontSize: 10, color: Colors.grey));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Xuất kho (Xanh dương)
                      LineChartBarData(
                        spots: _warehouseTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['export'].toDouble())).toList(),
                        isCurved: true, color: StaffTheme.primaryBlue, barWidth: 3, dotData: const FlDotData(show: false),
                        preventCurveOverShooting: true,
                        belowBarData: BarAreaData(show: true, color: StaffTheme.primaryBlue.withOpacity(0.1)),
                      ),
                      // Nhập kho (Xanh lá)
                      LineChartBarData(
                        spots: _warehouseTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['import'].toDouble())).toList(),
                        isCurved: true, color: Colors.green, barWidth: 3, dotData: const FlDotData(show: false),
                        preventCurveOverShooting: true,
                        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleLegend(StaffTheme.primaryBlue, "Xuất kho ($_currentUnit)"),
              const SizedBox(width: 20),
              _buildSimpleLegend(Colors.green, "Nhập kho ($_currentUnit)"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, String value) {
    bool isSelected = _trendPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _trendPeriod = value);
        refreshData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? StaffTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 10, fontWeight: FontWeight.bold
        )),
      ),
    );
  }

  /// 📦 Ô THỐNG KÊ TỔNG QUAN (2/5)
  Widget _buildMissionSummaryCard() {
    return Column(
      children: [
        _buildStatBox("TỔNG NHIỆM VỤ", _extendedStats['totalCompletedMissions']?.toString() ?? "0", Colors.purple, Icons.assignment_turned_in),
        const SizedBox(height: 15),
        _buildStatBox("NGƯỜI ĐÃ CỨU", _extendedStats['totalPeopleRescued']?.toString() ?? "0", Colors.orange, Icons.people),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: StaffTheme.softShadow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  /// ⛑️ LỊCH SỬ CỨU HỘ
  Widget _buildRescueHistoryList() {
    if (_rescueHistory.isEmpty) return _buildNoDataCard();
    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: _rescueScrollController,
        child: ListView.builder(
          controller: _rescueScrollController,
          primary: false,
          padding: const EdgeInsets.only(right: 10),
          itemCount: _rescueHistory.length,
          itemBuilder: (context, index) {
            final item = _rescueHistory[index];
            return _buildHistoryCard(
              icon: Icons.health_and_safety,
              color: Colors.red,
              title: "Nhiệm vụ: ${item['citizenName'] ?? 'Không tên'}",
              subtitle: "${item['location'] ?? 'N/A'} • ${item['peopleCount']} người",
              time: _formatDateTime(item['time']),
              trailing: _buildCompletionBadge(item['completionLevel']),
              onTap: () => _showRescueDetail(item),
            );
          },
        ),
      ),
    );
  }

  /// 📦 LỊCH SỬ XUẤT NHẬP HÀNG HÓA
  Widget _buildWarehouseHistorySection() {
    return Column(
      children: [
        Row(
          children: [
            _buildTabButton("XUẤT KHO", 0, Icons.outbox),
            const SizedBox(width: 10),
            _buildTabButton("NHẬP KHO", 1, Icons.move_to_inbox),
          ],
        ),
        const SizedBox(height: 15),
        _warehouseTab == 0 ? _buildExportList() : _buildImportList(),
      ],
    );
  }

  Widget _buildExportList() {
    if (_exportHistory.isEmpty) return _buildNoDataCard();
    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: _exportScrollController,
        child: ListView.builder(
          controller: _exportScrollController,
          primary: false,
          padding: const EdgeInsets.only(right: 10),
          itemCount: _exportHistory.length,
          itemBuilder: (context, index) {
            final item = _exportHistory[index];
            return _buildHistoryCard(
              icon: Icons.upload,
              color: StaffTheme.primaryBlue,
              title: "Xuất: ${item['itemName']}",
              subtitle: "SL: ${item['quantity']} • ${item['reason'] ?? 'Cứu hộ'}",
              time: _formatDateTime(item['time']),
              onTap: () => _showWarehouseDetail(item, 'EXPORT'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImportList() {
    if (_importHistory.isEmpty) return _buildNoDataCard();
    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: _importScrollController,
        child: ListView.builder(
          controller: _importScrollController,
          primary: false,
          padding: const EdgeInsets.only(right: 10),
          itemCount: _importHistory.length,
          itemBuilder: (context, index) {
            final item = _importHistory[index];
            return _buildHistoryCard(
              icon: Icons.download,
              color: Colors.green,
              title: "Nhập: ${item['itemName']}",
              subtitle: "SL: ${item['quantity']} • ${item['source'] ?? 'N/A'}",
              time: _formatDateTime(item['time']),
              onTap: () => _showWarehouseDetail(item, 'IMPORT'),
            );
          },
        ),
      ),
    );
  }

  /// 🛥️ LỊCH SỬ SỬ DỤNG PHƯƠNG TIỆN
  Widget _buildVehicleUsageHistoryList() {
    if (_vehicleHistory.isEmpty) return _buildNoDataCard();
    return SizedBox(
      height: 300,
      child: Scrollbar(
        controller: _vehicleScrollController,
        child: ListView.builder(
          controller: _vehicleScrollController,
          primary: false,
          padding: const EdgeInsets.only(right: 10),
          itemCount: _vehicleHistory.length,
          itemBuilder: (context, index) {
            final item = _vehicleHistory[index];
            final List vehicles = item['vehicles'] ?? [];
            return _buildHistoryCard(
              icon: Icons.directions_boat,
              color: Colors.indigo,
              title: item['location'] ?? "Nhiệm vụ #${item['assignmentId'].toString().substring(0, 5)}",
              subtitle: vehicles.isEmpty ? "Không rõ phương tiện" : "Xe: ${vehicles.map((v) => v['licensePlate']).join(', ')}",
              time: _formatDateTime(item['time']),
              trailing: _buildStatusBadge(item['status']),
              onTap: () => _showVehicleDetail(item),
            );
          },
        ),
      ),
    );
  }

  // --- MODALS CHI TIẾT ---

  void _showRescueDetail(Map<String, dynamic> item) {
    _showAppModal("Chi tiết Nhiệm vụ", Column(
      children: [
        _buildDetailRow("Tên hộ dân:", item['citizenName'] ?? 'N/A'),
        _buildDetailRow("Địa chỉ:", item['location'] ?? 'N/A'),
        _buildDetailRow("Số người:", item['peopleCount'].toString()),
        _buildDetailRow("Trạng thái:", item['status']),
        const Divider(),
        _buildDetailRow("Mức độ hoàn thành:", "${item['completionLevel']}%", valueColor: Colors.blue),
      ],
    ));
  }

  void _showWarehouseDetail(Map<String, dynamic> item, String type) {
    _showAppModal("Chi tiết ${type == 'EXPORT' ? 'Xuất kho' : 'Nhập hàng'}", Column(
      children: [
        _buildDetailRow("Vật phẩm:", item['itemName']),
        _buildDetailRow("Số lượng:", item['quantity'].toString()),
        _buildDetailRow("Thời gian:", _formatDateTime(item['time'])),
        _buildDetailRow("Mã tham chiếu:", item['reference'] ?? 'N/A'),
        if (type == 'EXPORT') _buildDetailRow("Lý do xuất:", item['reason'] ?? 'Cứu hộ'),
        if (type == 'IMPORT') _buildDetailRow("Nguồn nhập:", item['source'] ?? 'N/A'),
      ],
    ));
  }

  void _showVehicleDetail(Map<String, dynamic> item) {
    final List vehicles = item['vehicles'] ?? [];
    _showAppModal("Chi tiết Sử dụng Xe", Column(
      children: [
        _buildDetailRow("Vị trí:", item['location'] ?? 'N/A'),
        _buildDetailRow("Thời gian bắt đầu:", _formatDateTime(item['time'])),
        _buildDetailRow("Trạng thái nhiệm vụ:", item['status']),
        _buildDetailRow("Tình trạng:", _getReturnStatus(item['status']), valueColor: Colors.green),
        const SizedBox(height: 15),
        const Align(alignment: Alignment.centerLeft, child: Text("PHƯƠNG TIỆN SỬ DỤNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
        const SizedBox(height: 10),
        ...vehicles.map((v) => Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${v['licensePlate']} (${v['type']})", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(v['vStatus'], style: const TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
        )).toList(),
      ],
    ));
  }

  // --- UI COMPONENTS ---

  Widget _buildTabButton(String label, int index, IconData icon) {
    bool isSelected = _warehouseTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _warehouseTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? StaffTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? StaffTheme.primaryBlue : Colors.grey[300]!),
            boxShadow: isSelected ? StaffTheme.softShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({required IconData icon, required Color color, required String title, required String subtitle, required String time, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: StaffTheme.softShadow),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontSize: 12, color: StaffTheme.textMedium, fontWeight: FontWeight.bold)),
            if (trailing != null) ...[const SizedBox(height: 6), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBadge(int level) {
    Color c = level == 100 ? Colors.green : (level > 40 ? Colors.blue : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text("$level%", style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color c = status == 'COMPLETED' ? Colors.green : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status == 'COMPLETED' ? 'Đã xong' : 'Đang đi', style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSimpleLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppModal(String title, Widget content) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(height: 30),
            content,
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Đóng", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic time) {
    if (time == null) return "N/A";
    try {
      DateTime dt = DateTime.parse(time.toString());
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (e) { return time.toString(); }
  }

  String _getReturnStatus(String status) {
    if (status == 'COMPLETED') return "Đã trả xe về kho";
    return "Đang hoạt động";
  }

  Widget _buildGroupedSection({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StaffTheme.border),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              _buildSectionTitle(title),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: StaffTheme.border),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: StaffTheme.textDark, letterSpacing: 0.8));
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: StaffTheme.softShadow),
      child: const Center(child: Text("Không có dữ liệu hiển thị", style: TextStyle(color: Colors.grey, fontSize: 12))),
    );
  }
}
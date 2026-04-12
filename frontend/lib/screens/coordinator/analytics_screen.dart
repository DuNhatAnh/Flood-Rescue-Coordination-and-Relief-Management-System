import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminService.fetchDetailedAnalytics();
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê & Báo Cáo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_analytics == null || _analytics!.isEmpty)
              ? const Center(child: Text('Không có dữ liệu'))
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildKpiCard(
                  'Tổng yêu cầu',
                  _analytics?['totalRequests']?.toString() ?? '0',
                  Icons.assignment,
                  Colors.blue),
              _buildKpiCard(
                  'Đội cứu hộ',
                  _analytics?['totalTeams']?.toString() ?? '0',
                  Icons.security,
                  Colors.orange),
              _buildKpiCard(
                  'Đã cứu hộ (Dự kiến)',
                  _analytics?['totalPeopleRescued']?.toString() ?? '0',
                  Icons.people,
                  Colors.green),
            ],
          ),
          const SizedBox(height: 24),

          // Charts Section
          if (screenWidth > 900)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPieChartSection()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildLineChartSection()),
              ],
            )
          else
            Column(
              children: [
                _buildPieChartSection(),
                const SizedBox(height: 16),
                _buildLineChartSection(),
              ],
            ),

          const SizedBox(height: 16),
          _buildItemsListSection(),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    final statusData =
        _analytics?['statusDistribution'] as Map<String, dynamic>? ?? {};

    // Define exact colors for statuses to match request urgency
    final Map<String, Color> statusColors = {
      'PENDING': Colors.orange,
      'VERIFIED': Colors.blue,
      'ASSIGNED': Colors.purple,
      'IN_PROGRESS': Colors.cyan,
      'COMPLETED': Colors.green,
      'CANCELLED': Colors.red,
    };

    final Map<String, String> statusNames = {
      'PENDING': 'Chờ xử lý',
      'VERIFIED': 'Đã xác minh',
      'ASSIGNED': 'Đã phân công',
      'IN_PROGRESS': 'Đang xử lý',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã huỷ',
    };

    List<PieChartSectionData> sections = [];
    statusData.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          color: statusColors[key] ?? Colors.grey,
          value: value.toDouble(),
          title: '${value.toInt()}',
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
          color: Colors.grey[300]!, value: 1, title: '0', radius: 50));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trạng Thái Yêu Cầu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: statusData.entries
                  .where((e) => e.value > 0)
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              color: statusColors[e.key] ?? Colors.grey),
                          const SizedBox(width: 4),
                          Text('${statusNames[e.key] ?? e.key} (${e.value})',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartSection() {
    final trendData = _analytics?['requestTrend'] as List<dynamic>? ?? [];

    List<FlSpot> spots = [];
    List<String> dates = [];

    double maxY = 5.0; // minimum scale

    for (int i = 0; i < trendData.length; i++) {
      double value = (trendData[i]['count'] as num).toDouble();
      if (value > maxY) maxY = value;
      spots.add(FlSpot(i.toDouble(), value));

      String rawDate = trendData[i]['date'] as String;
      List<String> parts = rawDate.split('-');
      if (parts.length == 3) {
        dates.add('${parts[2]}/${parts[1]}');
      } else {
        dates.add(rawDate);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xu Hướng Yêu Cầu (7 ngày qua)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(dates[index],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 0,
                  minY: 0,
                  maxY: maxY * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF0288D1),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0288D1).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsListSection() {
    final topItems = _analytics?['topItems'] as List<dynamic>? ?? [];
    if (topItems.isEmpty) return const SizedBox.shrink();

    double maxVal = 0;
    for (var item in topItems) {
      if ((item['value'] as num).toDouble() > maxVal) {
        maxVal = (item['value'] as num).toDouble();
      }
    }
    if (maxVal == 0) maxVal = 1; // Prevent division by zero

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Số Lượng Hàng Hóa Điều Phối',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...topItems.map((item) {
              String name = item['name'] as String;
              double val = (item['value'] as num).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          FractionallySizedBox(
                            widthFactor: val / maxVal,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text('${val.toInt()}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

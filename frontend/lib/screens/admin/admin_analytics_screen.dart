import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
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
      if (mounted) {
        setState(() {
          _analytics = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải Báo cáo Phân tích: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8), // Nền màu xám xanh dịu mắt hơn
      appBar: AppBar(
        title: const Text('Báo Cáo Phân Tích Chuyên Sâu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadData,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_analytics == null || _analytics!.isEmpty)
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(),
                      const SizedBox(height: 24),
                      if (screenWidth > 1000)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPieChartSection()),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildLineChartSection()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildPieChartSection(),
                            const SizedBox(height: 24),
                            _buildLineChartSection(),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildItemsBarChartSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu thống kê', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopKpi('Tổng Số Yêu Cầu', '${_analytics?['totalRequests'] ?? 0}', Icons.description, Colors.blue.shade700),
          _buildDivider(),
          _buildTopKpi('Số Đội Y Tế / Cứu Hộ', '${_analytics?['totalTeams'] ?? 0}', Icons.security, Colors.deepPurple.shade600),
          _buildDivider(),
          _buildTopKpi('Số Người Đã Cứu', '${_analytics?['totalPeopleRescued'] ?? 0}', Icons.favorite, Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildTopKpi(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 16),
        Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.grey.shade800, height: 1.0)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPieChartSection() {
    final statusData = _analytics?['statusDistribution'] as Map<String, dynamic>? ?? {};

    final Map<String, Color> statusColors = {
      'PENDING': Colors.orange,
      'VERIFIED': Colors.blue,
      'ASSIGNED': Colors.purple,
      'IN_PROGRESS': Colors.cyan,
      'COMPLETED': Colors.green,
      'CANCELLED': Colors.red,
      'PREPARING': Colors.indigo,
      'REJECTED': Colors.brown,
      'MOVING': Colors.amber,
      'RESCUING': Colors.pink,
    };

    final Map<String, String> statusNames = {
      'PENDING': 'Chờ xử lý',
      'VERIFIED': 'Đã xác minh',
      'ASSIGNED': 'Đã phân công',
      'IN_PROGRESS': 'Đang xử lý',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã huỷ',
      'PREPARING': 'Đang chuẩn bị',
      'REJECTED': 'Từ chối',
      'MOVING': 'Đang di chuyển',
      'RESCUING': 'Đang giải cứu',
    };

    final List<Color> fallbackColors = [Colors.teal, Colors.lime, Colors.blueGrey, Colors.deepOrange];
    int fallbackIndex = 0;

    double total = 0;
    statusData.forEach((key, value) {
      if (value is num) total += value.toDouble();
    });

    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    statusData.forEach((key, value) {
      double val = (value as num).toDouble();
      if (val > 0) {
        Color sectionColor = statusColors[key] ?? fallbackColors[(fallbackIndex++) % fallbackColors.length];
        statusColors[key] = sectionColor; // Save custom generated color
        
        // Calculate percentage
        double percentage = (val / total) * 100;
        
        sections.add(PieChartSectionData(
          color: sectionColor,
          value: val,
          title: '${percentage.toStringAsFixed(1)}%', // Show Percentage instead of count inside pie
          radius: 55, // Thicker donut
          titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
            Shadow(color: Colors.black45, blurRadius: 2)
          ]),
        ));

        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, decoration: BoxDecoration(color: sectionColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(child: Text(statusNames[key] ?? key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800))),
                Text('${val.toInt()} yc', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          )
        );
      }
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '0%', radius: 60));
      legendItems.add(const Text("Chưa có yêu cầu cứu hộ nào", style: TextStyle(color: Colors.grey)));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text('TỈ LỆ TRẠNG THÁI CỨU HỘ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 24),
          // Bố cục thân thiện: Pie Chart bên trái, Chú giải xếp dọc bên phải gọn gàng
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sectionsSpace: 3, 
                    centerSpaceRadius: 45, 
                    sections: sections,
                  )),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: legendItems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartSection() {
    final trendData = _analytics?['requestTrend'] as List<dynamic>? ?? [];

    List<FlSpot> spots = [];
    List<String> dates = [];
    double maxY = 4.0; // Minimal default Y axis

    for (int i = 0; i < trendData.length; i++) {
      double value = (trendData[i]['count'] as num).toDouble();
      if (value > maxY) maxY = value;
      spots.add(FlSpot(i.toDouble(), value));

      // Rút gọn ngày (ví dụ 2024-04-12 -> 12/04)
      String rawDate = trendData[i]['date'] as String;
      List<String> parts = rawDate.split('-');
      if (parts.length == 3) {
        dates.add('${parts[2]}/${parts[1]}');
      } else {
        dates.add(rawDate);
      }
    }

    // Tăng chút xíu trục Y để dễ nhìn
    maxY = maxY + (maxY * 0.2); 
    if (maxY == 0) maxY = 5.0; 

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text('XU HƯỚNG YÊU CẦU CỨU HỘ (7 NGÀY QUA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 32),
          SizedBox(
            height: 250, // Định kích thước cố định thay vì Expanded để tránh lỗi render
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(dates[index], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.right),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 2), left: BorderSide(color: Colors.grey.shade400, width: 2))),
                minX: 0,
                maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 0,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blue.shade900,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} yêu cầu',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        );
                      }).toList();
                    }
                  )
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF2555D4),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 6, color: Colors.white, strokeWidth: 3, strokeColor: const Color(0xFF2555D4))),
                    belowBarData: BarAreaData(
                      show: true, 
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2555D4).withOpacity(0.3), const Color(0xFF2555D4).withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter
                      )
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsBarChartSection() {
    final topItems = _analytics?['topItems'] as List<dynamic>? ?? [];
    if (topItems.isEmpty) return const SizedBox.shrink();

    double maxVal = 0;
    for (var item in topItems) {
      double v = (item['value'] as num).toDouble();
      if (v > maxVal) { maxVal = v; }
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.teal.shade700),
              const SizedBox(width: 12),
              const Text('10 LOẠI HÀNG HOÁ TIÊU THỤ NHIỀU NHẤT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 24),
          ...topItems.map((item) {
            String name = item['name'] as String;
            if(name.isEmpty || name == "null") name = "Vật tư không xác định";
            double val = (item['value'] as num).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey.shade800), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(height: 20, decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
                        FractionallySizedBox(
                          widthFactor: val / maxVal,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00695C)]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 70,
                    child: Text('${val.toInt()}', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.teal.shade900)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

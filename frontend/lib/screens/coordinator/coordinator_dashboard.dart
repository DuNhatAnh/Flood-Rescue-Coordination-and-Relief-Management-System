import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';
import 'package:flood_rescue_app/models/safety_report.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';
import 'package:flood_rescue_app/screens/coordinator/assignment_screen.dart';
import 'package:flood_rescue_app/screens/home_screen.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({Key? key}) : super(key: key);

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  final RescueService _rescueService = RescueService();
  List<RescueRequest> _requests = [];
  List<SafetyReport> _safetyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _rescueService.getPendingRequests(),
        _rescueService.getSafetyReports(),
      ]);
      if (mounted) {
        setState(() {
          _requests = results[0] as List<RescueRequest>;
          _safetyReports = results[1] as List<SafetyReport>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điều Phối Cứu Hộ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Khu vực: Đà Nẵng', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            tooltip: 'Về trang chủ',
          ),
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              _buildStatsBar(_requests, _safetyReports),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        children: [
                          SizedBox(width: 400, child: _buildRequestList(_requests)),
                          Expanded(child: Stack(
                            children: [
                              _buildMap(_requests),
                              Positioned(right: 16, top: 16, child: _buildMapLegend()),
                            ],
                          )),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Expanded(flex: 2, child: Stack(
                            children: [
                              _buildMap(_requests),
                              Positioned(right: 16, top: 16, child: _buildMapLegend()),
                            ],
                          )),
                          Expanded(flex: 3, child: _buildRequestList(_requests)),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatsBar(List<RescueRequest> requests, List<SafetyReport> safetyReports) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length;
    final verified = requests.where((r) => r.isVerified).length;
    final people = requests.fold<int>(0, (sum, r) => sum + r.numberOfPeople);
    final safe = safetyReports.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard('Đang tiếp nhận', '$pending', Colors.red, Icons.emergency),
            _buildStatCard('Đã xác minh', '$verified', Colors.blue, Icons.verified),
            _buildStatCard('Người cần hỗ trợ', '$people', Colors.orange, Icons.people),
            _buildStatCard('Báo an toàn', '$safe', Colors.green, Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Độ khẩn cấp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildLegendRow('Cao', Colors.red),
          _buildLegendRow('Trung bình', Colors.orange),
          _buildLegendRow('Thấp', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<RescueRequest> requests) {
    final unverifiedRequests = requests.where((r) => !r.isVerified).toList();
    final verifiedRequests = requests.where((r) => r.isVerified).toList();

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: Color(0xFF0288D1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0288D1),
              tabs: [
                Tab(child: Text('Chờ xác minh (${unverifiedRequests.length})', style: TextStyle(fontSize: 13))),
                Tab(child: Text('Đã xác minh (${verifiedRequests.length})', style: TextStyle(fontSize: 13))),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFilteredList(unverifiedRequests, 'Không có yêu cầu chờ xác minh'),
                  _buildFilteredList(verifiedRequests, 'Không có yêu cầu đã xác minh'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList(List<RescueRequest> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(list[index]);
      },
    );
  }

  Widget _buildRequestCard(RescueRequest request) {
    final timeStr = DateFormat('HH:mm').format(request.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0, // Lower elevation for cleaner look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: request.urgencyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.urgencyLabel,
                          style: TextStyle(
                            color: request.urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (request.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ],
                  ),
                  Text(timeStr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.citizenName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${request.numberOfPeople} người',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      if (!request.isVerified)
                        IconButton(
                          onPressed: () async {
                            final success = await _rescueService.verifyRequest(request.id, 'Điều phối viên A');
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Yêu cầu đã được xác minh thành công')),
                              );
                              _refreshData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lỗi khi xác minh yêu cầu')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                          tooltip: 'Xác minh',
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        onPressed: () {
                          // Logic to forward to external agencies
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã chuyển tiếp thông tin sang Quân đội & Hội Chữ thập đỏ')),
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.orange, size: 20),
                        tooltip: 'Chuyển tiếp',
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () => _showRequestDetails(request),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: !request.isVerified ? null : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AssignmentScreen(request: request)),
                          );
                          if (result == true) {
                            _refreshData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: request.isVerified ? const Color(0xFF0288D1) : Colors.grey[300],
                          foregroundColor: request.isVerified ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          visualDensity: VisualDensity.compact,
                          elevation: request.isVerified ? 2 : 0,
                        ),
                        child: const Text('Điều phối', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(List<RescueRequest> requests) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(16.0471, 108.2062),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'flood_rescue_app',
        ),
        MarkerLayer(
          markers: requests.map((request) {
            return Marker(
              point: LatLng(request.lat, request.lng),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  // Show tooltip or info
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: request.urgencyColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      Icons.location_pin,
                      color: request.urgencyColor,
                      size: 36,
                    ),
                    Positioned(
                      top: 4,
                      child: Text(
                        '${request.urgency.index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showRequestDetails(RescueRequest initialRequest) {
    RescueRequest currentRequest = initialRequest;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chi tiết yêu cứu', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailRow(Icons.person, 'Người gửi', currentRequest.citizenName),
                    _buildDetailRow(Icons.phone, 'Số điện thoại', currentRequest.phone, isLink: true),
                    _buildDetailRow(Icons.location_on, 'Địa chỉ', currentRequest.address),
                    _buildDetailRow(Icons.people, 'Số người cần cứu', '${currentRequest.numberOfPeople} người'),
                    _buildDetailRow(Icons.priority_high, 'Mức độ khẩn cấp', currentRequest.urgencyLabel, color: currentRequest.urgencyColor),
                    _buildDetailRow(Icons.access_time, 'Thời gian gửi', DateFormat('dd/MM/yyyy HH:mm').format(currentRequest.createdAt)),
                    const SizedBox(height: 16),
                    const Text('Mô tả tình huống:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentRequest.description.isEmpty ? 'Không có mô tả' : currentRequest.description,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (!currentRequest.isVerified)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await _rescueService.verifyRequest(currentRequest.id, 'Điều phối viên');
                            if (success) {
                              setModalState(() {
                                currentRequest = currentRequest.copyWith(isVerified: true);
                              });
                              _refreshData(); // To keep main list updated
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xác minh yêu cầu'))
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.verified),
                          label: const Text('Xác minh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (!currentRequest.isVerified) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !currentRequest.isVerified ? null : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentScreen(request: currentRequest),
                            ),
                          ).then((_) => _refreshData());
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Điều phối'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentRequest.isVerified ? Colors.red : Colors.grey[300],
                          foregroundColor: currentRequest.isVerified ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: currentRequest.isVerified ? 2 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLink = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLink ? Colors.blue : (color ?? Colors.black87),
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../models/rescue_request.dart';
import '../../services/rescue_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'assignment_screen.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({Key? key}) : super(key: key);

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  final RescueService _rescueService = RescueService();
  late Future<List<RescueRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _requestsFuture = _rescueService.getPendingRequests();
    });
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
        actions: [
          IconButton(
            onPressed: () {
              AuthService.currentUser = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: FutureBuilder<List<RescueRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          
          final requests = snapshot.data ?? [];
          
          return Column(
            children: [
              _buildStatsBar(requests),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        children: [
                          SizedBox(width: 400, child: _buildRequestList(requests)),
                          Expanded(child: Stack(
                            children: [
                              _buildMap(requests),
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
                              _buildMap(requests),
                              Positioned(right: 16, top: 16, child: _buildMapLegend()),
                            ],
                          )),
                          Expanded(flex: 3, child: _buildRequestList(requests)),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(List<RescueRequest> requests) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length;
    final verified = requests.where((r) => r.isVerified).length;
    final people = requests.fold<int>(0, (sum, r) => sum + r.numberOfPeople);

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
            _buildStatCard('Đã cứu trợ', '39', Colors.green, Icons.check_circle),
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
          _buildLegendRow('Mức 5', Colors.red),
          _buildLegendRow('Mức 4', Colors.deepOrange),
          _buildLegendRow('Mức 3', Colors.orange),
          _buildLegendRow('Mức 2', Colors.lightGreen),
          _buildLegendRow('Mức 1', Colors.green),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yêu cứu chờ xử lý (${requests.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 16),
                  label: const Text('Mới nhất', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          requests.isEmpty 
            ? const Expanded(child: Center(child: Text('Không có yêu cầu nào')))
            : Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(request);
                  },
                ),
              ),
        ],
      ),
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
        onTap: () {
          // Click to center map or show details
        },
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
                          onPressed: () {
                            // Logic to verify request
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Yêu cầu đã được xác minh')),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                          tooltip: 'Xác minh',
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        onPressed: () {
                          // Logic to forward to external agencies
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã chuyển tiếp thông tin sang Quân đội')),
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.orange, size: 20),
                        tooltip: 'Chuyển tiếp',
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
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
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          visualDensity: VisualDensity.compact,
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
          userAgentPackageName: 'com.example.flood_rescue_app',
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
}

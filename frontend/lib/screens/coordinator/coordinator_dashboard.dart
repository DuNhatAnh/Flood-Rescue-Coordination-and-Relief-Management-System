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
          
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  children: [
                    SizedBox(width: 400, child: _buildRequestList(requests)),
                    Expanded(child: _buildMap(requests)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Expanded(flex: 2, child: _buildMap(requests)),
                    Expanded(flex: 3, child: _buildRequestList(requests)),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<RescueRequest> requests) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Yêu cầu chờ xử lý (${requests.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: request.urgencyColor.withOpacity(0.3), width: 1),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${request.numberOfPeople} người',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Chi tiết'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AssignmentScreen(request: request)),
                      );
                      // Nếu phân công thành công, load lại dữ liệu
                      if (result == true) {
                        _refreshData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Phân công'),
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
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  // Show tooltip or info
                },
                child: Icon(
                  Icons.location_pin,
                  color: request.urgencyColor,
                  size: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

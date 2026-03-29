import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/vehicle_service.dart';

class VehicleLocationScreen extends StatefulWidget {
  const VehicleLocationScreen({super.key});

  @override
  State<VehicleLocationScreen> createState() => _VehicleLocationScreenState();
}

class _VehicleLocationScreenState extends State<VehicleLocationScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = false;
  List<dynamic> _vehicles = [];
  final MapController _mapController = MapController();

  // Default coordinate (Center of Vietnam)
  static const LatLng _defaultCenter = LatLng(16.0544, 108.2022);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      // Fetch available vehicles or all. Let's fetch all vehicles for the map.
      // Using a large size to get most vehicles on map
      final result = await _vehicleService.getAllVehicles(page: 0, size: 100);
      setState(() {
        _vehicles = result['content'] ?? [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải vị trí: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  LatLng? _parseLocation(String? loc) {
    if (loc == null || loc.isEmpty) return null;
    try {
      final parts = loc.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    for (var v in _vehicles) {
      final locStr = v['currentLocation'] as String?;
      final latLng = _parseLocation(locStr);
      if (latLng != null) {
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: latLng,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('${v['vehicleType']} - ${v['licensePlate']}'),
                    content: Text('Trạng thái: ${v['status']}\nĐội: ${v['teamId'] ?? "Không có"}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                    ],
                  ),
                );
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40.0,
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Vị trí Phương tiện'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 5.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                'Tổng xe trên bản đồ: ${markers.length} / ${_vehicles.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

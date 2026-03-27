import 'package:flutter/material.dart';
import '../../services/vehicle_service.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = false;
  List<dynamic> _vehicles = [];
  int _currentPage = 0;
  int _totalPages = 1;
  String _searchType = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles({int page = 0}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _vehicleService.getAllVehicles(page: page, type: _searchType);
      setState(() {
        _vehicles = result['content'] ?? [];
        _currentPage = result['number'] ?? 0;
        _totalPages = result['totalPages'] ?? 1;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách xe: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? vehicle]) {
    final isEdit = vehicle != null;
    final typeController = TextEditingController(text: isEdit ? vehicle['vehicleType'] : '');
    final plateController = TextEditingController(text: isEdit ? vehicle['licensePlate'] : '');
    final locationController = TextEditingController(text: isEdit ? vehicle['currentLocation'] : '');
    final teamController = TextEditingController(text: isEdit ? vehicle['teamId'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Sửa Phương Tiện' : 'Thêm Phương Tiện'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Loại phương tiện (VD: Xuồng máy...)'),
                ),
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'Biển số / Định danh'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Vị trí hiện tại (Tọa độ GPS)',
                    hintText: 'VD: 16.0544, 108.2022',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      tooltip: 'Chọn trên bản đồ',
                      onPressed: () async {
                        LatLng? initialLoc;
                        if (locationController.text.isNotEmpty) {
                          try {
                            final parts = locationController.text.split(',');
                            if (parts.length >= 2) {
                              initialLoc = LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
                            }
                          } catch (_) {}
                        }
                        final LatLng? picked = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerScreen(initialLocation: initialLoc),
                          ),
                        );
                        if (picked != null) {
                          locationController.text = '${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
                        }
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: teamController,
                  decoration: const InputDecoration(labelText: 'ID Đội cứu hộ (tùy chọn)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'vehicleType': typeController.text.trim(),
                  'licensePlate': plateController.text.trim(),
                  'currentLocation': locationController.text.trim(),
                  'teamId': teamController.text.trim() == '' ? null : teamController.text.trim()
                };
                if (data['vehicleType'] == '' || data['licensePlate'] == '') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin bắt buộc')));
                  return;
                }
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  if (isEdit) {
                    await _vehicleService.updateVehicle(vehicle['id'], data);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
                  } else {
                    await _vehicleService.createVehicle(data);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm phương tiện thành công')));
                  }
                  _loadVehicles(page: _currentPage);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phương tiện này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _vehicleService.deleteVehicle(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
                _loadVehicles(page: _currentPage);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phương tiện'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo loại phương tiện...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      _searchType = val;
                      _loadVehicles();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm phương tiện'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2555D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_vehicles.isEmpty)
            const Expanded(child: Center(child: Text('Không có phương tiện nào')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final v = _vehicles[index];
                  // Determine status color
                  Color statusColor = Colors.grey;
                  if (v['status'] == 'AVAILABLE') statusColor = Colors.green;
                  if (v['status'] == 'IN_USE') statusColor = Colors.orange;
                  if (v['status'] == 'MAINTENANCE') statusColor = Colors.redAccent;

                  // Determine vehicle icon and color based on type
                  IconData vehicleIcon = Icons.directions_car;
                  Color iconColor = const Color(0xFF2555D4); // Mặc định xanh dương
                  
                  String typeMatch = (v['vehicleType'] ?? '').toString().toLowerCase();
                  if (typeMatch.contains('xuồng') || typeMatch.contains('thuyền') || typeMatch.contains('boat')) {
                    vehicleIcon = Icons.directions_boat;
                    iconColor = Colors.blue; 
                  } else if (typeMatch.contains('tải') || typeMatch.contains('truck')) {
                    vehicleIcon = Icons.local_shipping;
                    iconColor = Colors.orange; 
                  } else if (typeMatch.contains('ambulance') || typeMatch.contains('thương') || typeMatch.contains('cứu')) {
                    vehicleIcon = Icons.emergency_share;
                    iconColor = Colors.red; 
                  } else if (typeMatch.contains('trực thăng') || typeMatch.contains('heli')) {
                    vehicleIcon = Icons.flight;
                    iconColor = Colors.deepPurple;
                  } else if (typeMatch.contains('máy cày') || typeMatch.contains('tractor')) {
                    vehicleIcon = Icons.agriculture;
                    iconColor = Colors.brown;
                  } else if (typeMatch.contains('mô tô') || typeMatch.contains('moto') || typeMatch.contains('xe máy')) {
                    vehicleIcon = Icons.two_wheeler;
                    iconColor = Colors.teal;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(vehicleIcon, color: iconColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${v['vehicleType']} - ${v['licensePlate']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        v['status'] ?? 'N/A',
                                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security, 
                                            size: 14, 
                                            color: (v['teamId'] == null || v['teamId'].toString().isEmpty) ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              (v['teamId'] == null || v['teamId'].toString().isEmpty) ? 'Chưa gán đội' : 'Đội: ${v['teamId']}',
                                              style: TextStyle(
                                                color: (v['teamId'] == null || v['teamId'].toString().isEmpty) ? Colors.grey.shade400 : Colors.grey.shade600, 
                                                fontSize: 13,
                                                fontStyle: (v['teamId'] == null || v['teamId'].toString().isEmpty) ? FontStyle.italic : FontStyle.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on, 
                                      size: 14, 
                                      color: (v['currentLocation'] == null || v['currentLocation'].toString().trim().isEmpty) ? Colors.grey.shade400 : Colors.redAccent
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        (v['currentLocation'] != null && v['currentLocation'].toString().trim().isNotEmpty) ? v['currentLocation'] : 'Chưa rõ vị trí',
                                        style: TextStyle(
                                          fontSize: 13, 
                                          color: (v['currentLocation'] == null || v['currentLocation'].toString().trim().isEmpty) ? Colors.grey.shade500 : Colors.blueGrey.shade800,
                                          fontStyle: (v['currentLocation'] == null || v['currentLocation'].toString().trim().isEmpty) ? FontStyle.italic : FontStyle.normal,
                                          fontWeight: (v['currentLocation'] == null || v['currentLocation'].toString().trim().isEmpty) ? FontWeight.normal : FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_square, color: Color(0xFF2555D4)),
                                onPressed: () => _showAddEditDialog(v),
                                tooltip: 'Sửa',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(v['id']),
                                tooltip: 'Xóa',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0 ? () => _loadVehicles(page: _currentPage - 1) : null,
                ),
                Text('Trang ${_currentPage + 1} / $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1 ? () => _loadVehicles(page: _currentPage + 1) : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

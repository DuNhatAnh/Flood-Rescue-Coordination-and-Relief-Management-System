import 'package:flutter/material.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';
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
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles({int page = 0}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _vehicleService.getAllVehicles(
        page: page, 
        type: _searchType,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _vehicles = result['content'] ?? [];
          _currentPage = result['number'] ?? 0;
          _totalPages = result['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
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
    String currentStatus = isEdit ? (vehicle['status'] ?? 'AVAILABLE') : 'AVAILABLE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_circle_outline, color: const Color(0xFF2555D4)),
                const SizedBox(width: 10),
                Text(isEdit ? 'Sửa Phương Tiện' : 'Thêm Phương Tiện'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(typeController, 'Loại phương tiện', Icons.category, 'VD: Xuồng máy, Xe tải...'),
                  const SizedBox(height: 16),
                  _buildDialogField(plateController, 'Biển số / Định danh', Icons.credit_card, 'VD: 43A-12345'),
                  const SizedBox(height: 16),
                  _buildDialogField(
                    locationController, 
                    'Vị trí GPS', 
                    Icons.location_on, 
                    '16.0544, 108.2022',
                    suffix: IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
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
                          MaterialPageRoute(builder: (context) => LocationPickerScreen(initialLocation: initialLoc)),
                        );
                        if (picked != null) {
                          locationController.text = '${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField(teamController, 'ID Đội cứu hộ', Icons.group, 'Để trống nếu chưa gán'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'AVAILABLE', child: Text('Sẵn sàng')),
                      DropdownMenuItem(value: 'IN_USE', child: Text('Đang sử dụng')),
                      DropdownMenuItem(value: 'MAINTENANCE', child: Text('Bảo trì')),
                    ],
                    onChanged: (val) => setDialogState(() => currentStatus = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2555D4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  final adminId = AuthService.currentUser?.id ?? 'ADMIN';
                  final data = {
                    'vehicleType': typeController.text.trim(),
                    'licensePlate': plateController.text.trim(),
                    'currentLocation': locationController.text.trim(),
                    'teamId': teamController.text.trim() == '' ? null : teamController.text.trim(),
                    'status': currentStatus,
                  };
                  if (data['vehicleType'] == '' || data['licensePlate'] == '') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin')));
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    if (isEdit) {
                      await _vehicleService.updateVehicle(vehicle['id'], data, userId: adminId);
                    } else {
                      await _vehicleService.createVehicle(data, userId: adminId);
                    }
                    _loadVehicles(page: _currentPage);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, String hint, {Widget? suffix}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa?'),
        content: const Text('Hành động này không thể hoàn tác. Phương tiện sẽ được xóa khỏi hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final adminId = AuthService.currentUser?.id ?? 'ADMIN';
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _vehicleService.deleteVehicle(id, userId: adminId);
                _loadVehicles(page: _currentPage);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Xóa Ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý phương tiện', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading && _vehicles.isEmpty 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadVehicles(page: 0),
                  child: _vehicles.isEmpty 
                    ? const Center(child: Text('Không tìm thấy phương tiện nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) => _buildVehicleCard(_vehicles[index]),
                      ),
                ),
          ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2555D4),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo loại phương tiện...',
              hintStyle: const TextStyle(color: Colors.white),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onChanged: (val) {
              _searchType = val;
              _loadVehicles();
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterChip('Tất cả', null),
              const SizedBox(width: 8),
              _buildFilterChip('Sẵn sàng', 'AVAILABLE'),
              const SizedBox(width: 8),
              _buildFilterChip('Đang dùng', 'IN_USE'),
              const SizedBox(width: 8),
              _buildFilterChip('Bảo trì', 'MAINTENANCE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    bool isSelected = _statusFilter == value;
    return ChoiceChip(
      showCheckmark: isSelected,
      label: Text(
        label, 
        style: TextStyle(
          color: const Color(0xFF2555D4), // Luôn dùng chữ xanh để nét trên nền trắng
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = selected ? value : null);
        _loadVehicles();
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.85), // Nền chưa chọn là trắng trong suốt nhẹ
      surfaceTintColor: Colors.transparent, // Fix lỗi M3 tự tô màu
      elevation: 0,
      side: const BorderSide(color: Colors.white), // Viền trắng
      checkmarkColor: const Color(0xFF2555D4),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    Color statusColor = Colors.grey;
    String statusText = 'N/A';
    if (v['status'] == 'AVAILABLE') { statusColor = Colors.green; statusText = 'Sẵn sàng'; }
    if (v['status'] == 'IN_USE') { statusColor = Colors.orange; statusText = 'Đang sử dụng'; }
    if (v['status'] == 'MAINTENANCE') { statusColor = Colors.red; statusText = 'Bảo trì'; }

    IconData vehicleIcon = Icons.directions_car;
    Color iconColor = const Color(0xFF2555D4);
    String typeMatch = (v['vehicleType'] ?? '').toString().toLowerCase();
    if (typeMatch.contains('xuồng') || typeMatch.contains('thuyền')) { vehicleIcon = Icons.directions_boat; iconColor = Colors.blue; }
    else if (typeMatch.contains('tải')) { vehicleIcon = Icons.local_shipping; iconColor = Colors.orange; }
    else if (typeMatch.contains('thương') || typeMatch.contains('cứu')) { vehicleIcon = Icons.emergency; iconColor = Colors.red; }
    else if (typeMatch.contains('trực thăng')) { vehicleIcon = Icons.flight; iconColor = Colors.deepPurple; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 8,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                        child: Icon(vehicleIcon, color: iconColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['licensePlate'] ?? 'Chưa rõ BS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                            Text(v['vehicleType'] ?? 'Loại xe', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildBadge(statusText, statusColor),
                                const SizedBox(width: 8),
                                _buildBadge(v['teamId'] != null ? 'Đội: ${v['teamId']}' : 'Chưa gán đội', Colors.blueGrey.shade400, isOutline: true),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(child: Text(v['currentLocation'] ?? 'Chưa rõ vị trí', style: const TextStyle(fontSize: 12, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showAddEditDialog(v)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(v['id'])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _currentPage > 0 ? () => _loadVehicles(page: _currentPage - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF2555D4).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Trang ${_currentPage + 1} / $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2555D4))),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _currentPage < _totalPages - 1 ? () => _loadVehicles(page: _currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

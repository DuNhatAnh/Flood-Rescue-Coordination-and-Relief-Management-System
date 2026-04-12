import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/warehouse.dart';
import '../../services/warehouse_service.dart';
import '../../widgets/location_picker_dialog.dart';
import 'package:latlong2/latlong.dart' as ll;

class WarehouseManagementScreen extends StatefulWidget {
  const WarehouseManagementScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends State<WarehouseManagementScreen> {
  final AdminService _adminService = AdminService();
  final WarehouseService _warehouseService = WarehouseService();
  List<Warehouse> _warehouses = [];
  List<dynamic> _allStaff = [];
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final warehousesJson = await _adminService.getWarehouses();
      final users = await _adminService.getUsers();
      
      // Filter only Rescue Staff for naming as managers
      final staff = users.where((u) => u != null && u is Map && u['roleId'] == 'RESCUE_STAFF').toList();
      
      if (!mounted) return;
      setState(() {
        _warehouses = warehousesJson
            .where((j) => j != null)
            .map((j) => Warehouse.fromJson(j as Map<String, dynamic>))
            .toList();
        _allStaff = staff;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error loading warehouse data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }

  }

  void _showWarehouseDialog([Warehouse? warehouse]) {
    final nameController = TextEditingController(text: warehouse?.warehouseName);
    final locationController = TextEditingController(text: warehouse?.location);
    final latController = TextEditingController(text: warehouse?.latitude?.toString() ?? '');
    final lngController = TextEditingController(text: warehouse?.longitude?.toString() ?? '');
    String? selectedManager = warehouse?.managerId;
    
    // Ensure selectedManager is in the _allStaff list
    if (selectedManager != null && !_allStaff.any((s) => s['id'] == selectedManager)) {
      selectedManager = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(warehouse == null ? 'Thêm kho bãi mới' : 'Cập nhật kho bãi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên kho', hintText: 'VD: Kho Liên Chiểu'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ/Vị trí'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedManager,

                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('Chưa gán quản lý')),
                        ..._allStaff.map((staff) => DropdownMenuItem<String>(
                          value: staff['id'],
                          child: Text(staff['fullName'] ?? staff['email'] ?? 'Không tên'),
                        )).toList(),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedManager = val);
                      },
                      decoration: const InputDecoration(labelText: 'Người quản lý (Staff)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: latController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Vĩ độ (Lat)', hintText: '16.0'),
                              ),
                              TextField(
                                controller: lngController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Kinh độ (Lng)', hintText: '108.2'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.travel_explore, color: Colors.blue),
                          tooltip: 'Tìm từ địa chỉ',
                          onPressed: () async {
                            final coords = await _warehouseService.searchCoordinates(locationController.text);
                            if (coords != null) {
                              latController.text = coords['lat'].toString();
                              lngController.text = coords['lng'].toString();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.map_outlined, color: Colors.blue),
                          tooltip: 'Chọn trên bản đồ',
                          onPressed: () async {
                            final ll.LatLng? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationPickerDialog(
                                  initialPosition: double.tryParse(latController.text) != null && double.tryParse(lngController.text) != null
                                    ? ll.LatLng(double.parse(latController.text), double.parse(lngController.text))
                                    : null,
                                ),
                              ),
                            );
                            if (result != null) {
                              latController.text = result.latitude.toStringAsFixed(6);
                              lngController.text = result.longitude.toStringAsFixed(6);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    
                    final data = {
                      'warehouseName': nameController.text,
                      'location': locationController.text,
                      'managerId': selectedManager,
                      'status': 'ACTIVE',
                      'latitude': double.tryParse(latController.text),
                      'longitude': double.tryParse(lngController.text),
                    };

                    try {
                      if (warehouse == null) {
                        await _adminService.createWarehouse(data);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo kho bãi mới thành công')));
                      } else {
                        await _adminService.updateWarehouse(warehouse.id!, data);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật kho bãi thành công')));
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadData();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                  child: Text(warehouse == null ? 'Tạo mới' : 'Lưu thay đổi'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị Kho bãi'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWarehouseDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _warehouses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(

                  padding: const EdgeInsets.all(16),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final w = _warehouses[index];
                    final manager = _allStaff.firstWhere(
                      (s) => s != null && s is Map && s['id']?.toString() == w.managerId,
                      orElse: () => null,
                    );


                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.store, color: Colors.orange),
                        ),
                        title: Text(
                          w.warehouseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(w.location)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Quản lý: ',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  manager != null ? (manager['fullName'] ?? manager['email'] ?? 'Không tên') : 'Chưa có',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: manager != null ? Colors.blue.shade800 : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showWarehouseDialog(w),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có kho bãi nào', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showWarehouseDialog(),
            child: const Text('Thêm kho đầu tiên'),
          ),
        ],
      ),
    );
  }
}

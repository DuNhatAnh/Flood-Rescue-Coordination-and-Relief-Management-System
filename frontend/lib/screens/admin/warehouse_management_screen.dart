import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class WarehouseManagementScreen extends StatefulWidget {
  const WarehouseManagementScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends State<WarehouseManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _warehouses = [];
  List<dynamic> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _adminService.getWarehouses();
      final users = await _adminService.getUsers();
      
      // Filter only Rescue Staff for naming as managers
      final staff = users.where((u) => u['roleId'] == 'RESCUE_STAFF').toList();
      
      if (!mounted) return;
      setState(() {
        _warehouses = warehouses;
        _allStaff = staff;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  void _showWarehouseDialog([Map<String, dynamic>? warehouse]) {
    final nameController = TextEditingController(text: warehouse?['warehouseName']);
    final locationController = TextEditingController(text: warehouse?['location']);
    String? selectedManager = warehouse?['managerId'];
    
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
                          child: Text(staff['fullName'] ?? staff['email']),
                        )).toList(),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedManager = val);
                      },
                      decoration: const InputDecoration(labelText: 'Người quản lý (Staff)'),
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
                    };

                    try {
                      if (warehouse == null) {
                        await _adminService.createWarehouse(data);
                      } else {
                        await _adminService.updateWarehouse(warehouse['id'], data);
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
          : _warehouses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final w = _warehouses[index];
                    final manager = _allStaff.firstWhere(
                      (s) => s['id'] == w['managerId'],
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
                          w['warehouseName'] ?? 'Không tên',
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
                                Expanded(child: Text(w['location'] ?? 'Chưa cập nhật địa chỉ')),
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
                                  manager != null ? (manager['fullName'] ?? manager['email']) : 'Chưa có',
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

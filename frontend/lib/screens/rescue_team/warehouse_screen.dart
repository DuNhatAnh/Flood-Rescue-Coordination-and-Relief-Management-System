import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
import '../../services/warehouse_service.dart';
import 'warehouse_inventory_screen.dart';
import 'distribution_export_screen.dart';
import 'distribution_history_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/staff_theme.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../widgets/location_picker_dialog.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({Key? key}) : super(key: key);

  @override
  WarehouseScreenState createState() => WarehouseScreenState();
}

class WarehouseScreenState extends State<WarehouseScreen> {
  final WarehouseService _service = WarehouseService();
  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'ALL';

  List<Warehouse> get _filteredWarehouses {
    return _warehouses.where((w) {
      final matchesSearch = w.warehouseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == 'ALL' || w.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadWarehouses();
  }

  Future<void> loadWarehouses() async {
    setState(() => _isLoading = true);
    final warehouses = await _service.getAll();
    
    warehouses.sort((a, b) {
      if (a.status == 'ACTIVE' && b.status != 'ACTIVE') return -1;
      if (a.status != 'ACTIVE' && b.status == 'ACTIVE') return 1;
      return a.warehouseName.compareTo(b.warehouseName);
    });

    setState(() {
      _warehouses = warehouses;
      _isLoading = false;
    });
  }

  void showAddDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    String selectedStatus = 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StaffTheme.cardRadius)),
          title: Text('Thêm Kho hàng mới', style: StaffTheme.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên kho',
                  hintText: 'VD: Kho Liên Chiểu',
                  prefixIcon: const Icon(Icons.warehouse_outlined, color: StaffTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm',
                  hintText: 'Quận Liên Chiểu, Đà Nẵng',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: StaffTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái ban đầu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.info_outline_rounded, color: StaffTheme.primaryBlue),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'MAINTENANCE', child: Text('Đang sửa chữa')),
                  DropdownMenuItem(value: 'CONSTRUCTING', child: Text('Đang xây dựng')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Tạm nghỉ')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Vĩ độ (Lat)',
                        hintText: '16.0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Kinh độ (Lng)',
                        hintText: '108.2',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút Tìm tọa độ từ địa chỉ
                  IconButton(
                    icon: Icon(Icons.travel_explore, color: StaffTheme.primaryBlue),
                    tooltip: 'Tìm từ địa chỉ',
                    onPressed: () async {
                      if (locationController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ trước')));
                        return;
                      }
                      final coords = await _service.searchCoordinates(locationController.text);
                      if (coords != null) {
                        latController.text = coords['lat'].toString();
                        lngController.text = coords['lng'].toString();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy tọa độ cho địa chỉ này')));
                        }
                      }
                    },
                  ),
                  // Nút Chọn trên bản đồ
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: StaffTheme.primaryBlue),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: StaffTheme.textLight))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final newWarehouse = Warehouse(
                  warehouseName: nameController.text,
                  location: locationController.text,
                  status: selectedStatus,
                  latitude: double.tryParse(latController.text),
                  longitude: double.tryParse(lngController.text),
                );
                
                final result = await _service.create(newWarehouse);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (result != null) {
                  loadWarehouses();
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void showEditDialog(Warehouse warehouse) {
    final nameController = TextEditingController(text: warehouse.warehouseName);
    final locationController = TextEditingController(text: warehouse.location);
    final latController = TextEditingController(text: warehouse.latitude?.toString() ?? '');
    final lngController = TextEditingController(text: warehouse.longitude?.toString() ?? '');
    String currentStatus = warehouse.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StaffTheme.cardRadius)),
          title: Text('Chỉnh sửa Kho', style: StaffTheme.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên kho',
                  prefixIcon: const Icon(Icons.warehouse_outlined, color: StaffTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: StaffTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: currentStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.info_outline_rounded, color: StaffTheme.primaryBlue),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'MAINTENANCE', child: Text('Đang sửa chữa')),
                  DropdownMenuItem(value: 'CONSTRUCTING', child: Text('Đang xây dựng')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Tạm nghỉ')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => currentStatus = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Vĩ độ (Lat)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Kinh độ (Lng)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.travel_explore, color: StaffTheme.primaryBlue),
                    onPressed: () async {
                      final coords = await _service.searchCoordinates(locationController.text);
                      if (coords != null) {
                        latController.text = coords['lat'].toString();
                        lngController.text = coords['lng'].toString();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: StaffTheme.primaryBlue),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: StaffTheme.textLight))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final updated = Warehouse(
                  id: warehouse.id,
                  warehouseName: nameController.text,
                  location: locationController.text,
                  status: currentStatus,
                  managerId: warehouse.managerId,
                  latitude: double.tryParse(latController.text),
                  longitude: double.tryParse(lngController.text),
                );
                
                final result = await _service.update(warehouse.id!, updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (result != null) loadWarehouses();
              },
              child: const Text('Cập nhật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteWarehouse(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StaffTheme.cardRadius)),
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa kho "${warehouse.warehouseName}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: StaffTheme.textLight))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa', style: TextStyle(color: StaffTheme.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && warehouse.id != null) {
      final success = await _service.delete(warehouse.id!);
      if (mounted && success) loadWarehouses();
    }
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tên kho hoặc địa điểm...',
              prefixIcon: const Icon(Icons.search_rounded, color: StaffTheme.primaryBlue),
              filled: true,
              fillColor: StaffTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributionExportScreen())),
                  icon: const Icon(Icons.outbox_rounded, size: 18, color: Colors.white),
                  label: const Text('XUẤT HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StaffTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributionHistoryScreen())),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('LỊCH SỬ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Hoạt động'),
                const SizedBox(width: 8),
                _buildFilterChip('MAINTENANCE', 'Sửa chữa'),
                const SizedBox(width: 8),
                _buildFilterChip('CONSTRUCTING', 'Đang xây'),
                const SizedBox(width: 8),
                _buildFilterChip('INACTIVE', 'Tạm nghỉ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    bool isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? StaffTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? StaffTheme.primaryBlue : StaffTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : StaffTheme.textMedium,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: StaffTheme.primaryBlue))
                : _filteredWarehouses.isEmpty
                    ? _buildEmptyState()
                    : _buildWarehouseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty || _filterStatus != 'ALL';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.house_siding_rounded,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Không tìm thấy kho phù hợp' : 'Chưa có dữ liệu kho bãi',
            style: const TextStyle(color: StaffTheme.textLight, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() { _searchQuery = ''; _filterStatus = 'ALL'; }),
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseList() {
    return RefreshIndicator(
      onRefresh: loadWarehouses,
      color: StaffTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filteredWarehouses.length,
        itemBuilder: (context, index) {
          final warehouse = _filteredWarehouses[index];
          return _buildWarehouseCard(warehouse);
        },
      ),
    );
  }

  Widget _buildWarehouseCard(Warehouse warehouse) {
    final Color statusColor = _getStatusColor(warehouse.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StaffTheme.cardRadius),
        border: Border.all(color: StaffTheme.border),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(StaffTheme.cardRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WarehouseInventoryScreen(warehouse: warehouse)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Professional Ledger Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StaffTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store_rounded, color: StaffTheme.primaryBlue.withOpacity(0.7), size: 32),
                ),
                const SizedBox(width: 16),
                // Warehouse Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(warehouse.warehouseName, style: StaffTheme.cardTitle),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: StaffTheme.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              warehouse.location,
                              style: StaffTheme.cardSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Professional Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(warehouse.status),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Menu - Only for Manager or Admin
                if (AuthService.currentUser?.role == UserRole.admin || 
                    AuthService.currentUser?.role == UserRole.coordinator ||
                    AuthService.currentUser?.id == warehouse.managerId)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: StaffTheme.textLight),
                    onSelected: (val) {
                      if (val == 'edit') showEditDialog(warehouse);
                      if (val == 'delete') deleteWarehouse(warehouse);
                      if (val == 'export') {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DistributionExportScreen()),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Sửa')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [Icon(Icons.outbox_rounded, size: 20, color: StaffTheme.primaryBlue), SizedBox(width: 8), Text('Xuất hàng khẩn cấp')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [Icon(Icons.delete_outline, size: 20, color: StaffTheme.errorRed), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: StaffTheme.errorRed))],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE': return StaffTheme.successGreen;
      case 'MAINTENANCE': return StaffTheme.warningOrange;
      case 'CONSTRUCTING': return StaffTheme.primaryBlue;
      default: return StaffTheme.errorRed;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE': return 'HOẠT ĐỘNG';
      case 'MAINTENANCE': return 'BẢO TRÌ';
      case 'CONSTRUCTING': return 'ĐANG XÂY';
      case 'INACTIVE': return 'TẠM NGHỈ';
      default: return status;
    }
  }
}

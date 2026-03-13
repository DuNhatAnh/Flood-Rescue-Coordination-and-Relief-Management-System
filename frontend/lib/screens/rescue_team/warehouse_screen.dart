import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
import '../../services/warehouse_service.dart';
import '../relief_item_screen.dart';

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
    
    // Priority Sorting: ACTIVE first, then alphabetical (optional but good)
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
    String selectedStatus = 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thêm Kho hàng mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên kho',
                  hintText: 'VD: Kho Liên Chiểu',
                  prefixIcon: const Icon(Icons.warehouse_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm',
                  hintText: 'Quận Liên Chiểu, Đà Nẵng',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái ban đầu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.info_outline_rounded),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên kho')));
                  return;
                }
                
                final newWarehouse = Warehouse(
                  warehouseName: nameController.text,
                  location: locationController.text,
                  status: selectedStatus,
                );
                
                final result = await _service.create(newWarehouse);
                if (mounted) {
                  Navigator.pop(context);
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm kho ${newWarehouse.warehouseName} thành công!'), backgroundColor: Colors.green),
                    );
                    loadWarehouses();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi: Không thể kết nối đến máy chủ.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void showEditDialog(Warehouse warehouse) {
    final nameController = TextEditingController(text: warehouse.warehouseName);
    final locationController = TextEditingController(text: warehouse.location);
    String currentStatus = warehouse.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Chỉnh sửa Kho', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên kho',
                  prefixIcon: const Icon(Icons.warehouse_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: currentStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final updated = Warehouse(
                  id: warehouse.id,
                  warehouseName: nameController.text,
                  location: locationController.text,
                  status: currentStatus,
                  managerId: warehouse.managerId,
                );
                
                final result = await _service.update(warehouse.id!, updated);
                if (mounted) {
                  Navigator.pop(context);
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật thông tin kho thành công!'), backgroundColor: Colors.green),
                    );
                    loadWarehouses();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi cập nhật kho.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Cập nhật', style: TextStyle(color: Colors.white)),
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
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa kho "${warehouse.warehouseName}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && warehouse.id != null) {
      final success = await _service.delete(warehouse.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa kho.'), backgroundColor: Colors.black87),
          );
          loadWarehouses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa kho.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên kho hoặc địa điểm...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0288D1)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả'),
                    _buildFilterChip('ACTIVE', 'Hoạt động'),
                    _buildFilterChip('MAINTENANCE', 'Sửa chữa'),
                    _buildFilterChip('CONSTRUCTING', 'Đang xây'),
                    _buildFilterChip('INACTIVE', 'Tạm nghỉ'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF0288D1), size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReliefItemScreen()),
                );
              },
              tooltip: 'Quản lý Danh mục',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    bool isSelected = _filterStatus == status;
    Color themeColor = const Color(0xFF0288D1);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      selectedColor: themeColor,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
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
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Không tìm thấy kho phù hợp' : 'Chưa có dữ liệu kho bãi',
            style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? 'Thử thay đổi từ khóa hoặc bộ lọc' : 'Nhấn nút "+" bên dưới để thêm kho mới',
            style: const TextStyle(color: Colors.grey),
          ),
          if (isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterStatus = 'ALL';
                  });
                },
                child: const Text('Xóa bộ lọc'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarehouseList() {
    return RefreshIndicator(
      onRefresh: loadWarehouses,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _filteredWarehouses.length,
        itemBuilder: (context, index) {
          final warehouse = _filteredWarehouses[index];
          return _buildWarehouseCard(warehouse);
        },
      ),
    );
  }

  Widget _buildWarehouseCard(Warehouse warehouse) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(warehouse.status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(warehouse.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(warehouse.status).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded, color: Color(0xFF0288D1)),
              ),
              title: Text(
                warehouse.warehouseName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warehouse.location,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusTag(warehouse.status),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') showEditDialog(warehouse);
                  if (val == 'delete') deleteWarehouse(warehouse);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Sửa thông tin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa kho', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Future: Xem chi tiết tồn kho
              },
            ),
            if (warehouse.status != 'ACTIVE') _buildRibbon(warehouse.status),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'MAINTENANCE':
        return Colors.orange;
      case 'CONSTRUCTING':
        return Colors.blue;
      case 'INACTIVE':
      default:
        return Colors.red;
    }
  }

  Widget _buildRibbon(String status) {
    final color = _getStatusColor(status);
    String label;
    
    switch (status) {
      case 'MAINTENANCE':
        label = 'BẢO TRÌ';
        break;
      case 'CONSTRUCTING':
        label = 'ĐANG XÂY';
        break;
      case 'INACTIVE':
      default:
        label = 'TẠM DỪNG';
        break;
    }

    return Positioned(
      top: 15,
      right: -35,
      child: Transform.rotate(
        angle: 0.785, // 45 degrees
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    final color = _getStatusColor(status);
    String label;
    
    switch (status) {
      case 'ACTIVE':
        label = 'ĐANG HOẠT ĐỘNG';
        break;
      case 'MAINTENANCE':
        label = 'ĐANG SỬA CHỮA';
        break;
      case 'CONSTRUCTING':
        label = 'ĐANG XÂY DỰNG';
        break;
      case 'INACTIVE':
      default:
        label = 'TẠM NGHỈ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

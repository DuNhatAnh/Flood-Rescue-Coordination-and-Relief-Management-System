import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/warehouse.dart';
import '../../models/inventory.dart';
import '../../services/warehouse_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/staff_theme.dart';
import '../../models/vehicle.dart';
import 'distribution_export_screen.dart';

class StaffManagedWarehouseScreen extends StatefulWidget {
  const StaffManagedWarehouseScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagedWarehouseScreen> createState() => _StaffManagedWarehouseScreenState();
}

class _StaffManagedWarehouseScreenState extends State<StaffManagedWarehouseScreen> with SingleTickerProviderStateMixin {
  final WarehouseService _warehouseService = WarehouseService();
  final InventoryService _inventoryService = InventoryService();
  final VehicleService _vehicleService = VehicleService();
  
  late TabController _tabController;
  Warehouse? _myWarehouse;
  List<Warehouse> _allWarehouses = [];
  List<Inventory> _inventory = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  // Import form state
  String? _importSource;
  Inventory? _selectedImportItem;
  final TextEditingController _importQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final String? userId = AuthService.currentUser?.id;
      if (userId == null) return;

      // 1. Get managed warehouse
      final managed = await _warehouseService.getByManagerId(userId);
      
      // 2. Get all warehouses for map
      final all = await _warehouseService.getAll();

      // 3. Get vehicles
      List<Vehicle> vehicles = [];
      try {
        final vehicleData = await _vehicleService.getAvailableVehicles();
        vehicles = vehicleData.map((v) => Vehicle.fromJson(v)).toList();
      } catch (e) {
        print('Error fetching vehicles: $e');
      }

      setState(() {
        _myWarehouse = managed;
        _allWarehouses = all;
        _vehicles = vehicles;
      });

      // 4. Get inventory if managed exists
      if (managed != null) {
        final inv = await _inventoryService.getWarehouseInventory(managed.id!);
        setState(() => _inventory = inv);
      }
    } catch (e) {
      print('Error loading management data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_myWarehouse == null) return _buildNoWarehouseState();

    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_myWarehouse!.warehouseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Info & Map
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarehouseInfoCard(),
                        const SizedBox(height: 20),
                        _buildMapSection(height: 400),
                      ],
                    ),
                  ),
                ),
                // Right Panel: Inventory List
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: StaffTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        _buildInventoryHeader(),
                        const Divider(height: 1),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInventoryList(isScrollable: true),
                              _buildVehicleList(isScrollable: true),
                            ],
                          ),
                        ),
                        _buildBottomActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout (Current)
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildWarehouseInfoCard(),
                    )),
                    SliverToBoxAdapter(child: _buildMapSection()),
                    SliverToBoxAdapter(child: _buildInventoryHeader()),
                    // For mobile, we might want both or a different toggle. 
                    // Let's keep it simple: show Inventory first then Vehicles
                    _buildInventoryList(isScrollable: false),
                    const SliverToBoxAdapter(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('PHƯƠNG TIỆN CỨU HỘ', style: TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.textMedium)),
                    )),
                    _buildVehicleList(isScrollable: false),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
                _buildBottomActionButtons(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildWarehouseInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: StaffTheme.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _myWarehouse!.location,
                  style: StaffTheme.cardSubtitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Quản lý trực tiếp các hoạt động tại chỗ, điều phối hàng hóa cứu trợ khẩn cấp.',
            style: TextStyle(fontSize: 12, color: StaffTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection({double height = 250}) {
    final LatLng center = const LatLng(16.0544, 108.2023); 

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: StaffTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'vn.rescue.core',
            ),
            MarkerLayer(
              markers: _allWarehouses.map((w) {
                final isMine = w.id == _myWarehouse?.id;
                return Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showWarehouseQuickView(w),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: isMine ? Colors.orange : StaffTheme.primaryBlue,
                      size: isMine ? 40 : 30,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DANH MỤC QUẢN LÝ', style: TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.textMedium, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: StaffTheme.background, borderRadius: BorderRadius.circular(20)),
                child: Text('${_inventory.length} hàng, ${_vehicles.length} xe', style: const TextStyle(color: StaffTheme.textLight, fontSize: 11)),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: StaffTheme.primaryBlue,
          unselectedLabelColor: StaffTheme.textLight,
          indicatorColor: StaffTheme.primaryBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'HÀNG HÓA'),
            Tab(text: 'PHƯƠNG TIỆN'),
          ],
        ),
      ],
    );
  }

  dynamic _buildVehicleList({required bool isScrollable}) {
    final content = (context, index) {
      final vehicle = _vehicles[index];
      final bool isAvailable = vehicle.status == 'AVAILABLE';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: StaffTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: StaffTheme.background, borderRadius: BorderRadius.circular(10)),
              child: Icon(_getVehicleIcon(vehicle.vehicleType), color: StaffTheme.primaryBlue, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(vehicle.vehicleType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? StaffTheme.successGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAvailable ? 'SẴN SÀNG' : 'ĐANG DÙNG',
                          style: TextStyle(color: isAvailable ? StaffTheme.successGreen : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('Biển số: ${vehicle.licensePlate}', style: StaffTheme.cardSubtitle),
                ],
              ),
            ),
          ],
        ),
      );
    };

    if (isScrollable) {
      if (_vehicles.isEmpty) return const Center(child: Text('Không có phương tiện nào', style: TextStyle(color: Colors.grey)));
      return ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (ctx, idx) => content(ctx, idx),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) => content(ctx, idx),
          childCount: _vehicles.length,
        ),
      );
    }
  }

  IconData _getVehicleIcon(String type) {
    if (type.contains('Xuồng')) return Icons.directions_boat_filled_rounded;
    if (type.contains('Xe tải')) return Icons.local_shipping_rounded;
    if (type.contains('Xe bán tải')) return Icons.directions_car_filled_rounded;
    return Icons.local_shipping; // Fallback
  }

  dynamic _buildInventoryList({required bool isScrollable}) {
    final content = (context, index) {
      final item = _inventory[index];
      final bool isLowStock = item.quantity < 100; // Định mức mặc định
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isLowStock ? Colors.red.withOpacity(0.3) : StaffTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            // Hình ảnh minh họa
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: StaffTheme.background,
                child: Icon(_getItemIcon(item.itemName), color: StaffTheme.primaryBlue, size: 30),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditThresholdDialog(item),
                        child: Icon(Icons.edit_notifications_outlined, size: 18, color: isLowStock ? Colors.red : StaffTheme.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (item.quantity / 1000).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade100,
                          color: isLowStock ? Colors.red : StaffTheme.successGreen,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.w900, color: isLowStock ? Colors.red : StaffTheme.textMedium)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    };

    if (isScrollable) {
      return ListView.builder(
        itemCount: _inventory.length,
        itemBuilder: (ctx, idx) => content(ctx, idx),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) => content(ctx, idx),
          childCount: _inventory.length,
        ),
      );
    }
  }

  IconData _getItemIcon(String name) {
    if (name.contains('Gạo')) return Icons.grain;
    if (name.contains('Nước')) return Icons.water_drop;
    if (name.contains('Mì')) return Icons.fastfood;
    if (name.contains('Áo phao')) return Icons.emergency;
    return Icons.inventory_2_rounded;
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showImportDialog(),
              icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
              label: const Text('NHẬP HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showExportDialog(),
              icon: const Icon(Icons.outbox_rounded, color: Colors.white),
              label: const Text('XUẤT HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditThresholdDialog(item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Định mức cảnh báo: ${item.itemName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thiết lập số lượng tối thiểu để nhận cảnh báo hết hàng.'),
            const SizedBox(height: 15),
            TextField(
              decoration: const InputDecoration(labelText: 'Số lượng tối thiểu', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '100'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cập nhật')),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext ctx) async {
    if (_myWarehouse == null || _selectedImportItem == null || _importSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
      return;
    }

    final int? qty = int.tryParse(_importQtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số lượng không hợp lệ')));
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(ctx); // Close dialog first

    try {
      await _inventoryService.importStock(
        _myWarehouse!.id!,
        _selectedImportItem!.itemId,
        qty,
        source: _importSource,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập kho thành công!'), backgroundColor: StaffTheme.successGreen));
      _loadData(); // Refresh current inventory
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: StaffTheme.errorRed));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImportDialog() {
    // Reset state
    _importSource = null;
    _selectedImportItem = null;
    _importQtyController.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(gradient: StaffTheme.primaryGradient),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BIỂU MẪU NHẬP HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. THÔNG TIN NGUỒN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight, letterSpacing: 1.1)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: StaffTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Chọn nguồn cung cấp (Trung ương/...)', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        value: _importSource,
                        items: ['Cứu trợ Trung ương', 'Mạnh thường quân', 'Điều chuyển từ kho khác', 'Nhập khẩu hỗ trợ']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setDialogState(() => _importSource = val),
                      ),
                      const SizedBox(height: 20),
                      const Text('2. CHI TIẾT LÔ HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight, letterSpacing: 1.1)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<Inventory>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: StaffTheme.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                hintText: 'Tên hàng',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              value: _selectedImportItem,
                              items: _inventory.map((e) => DropdownMenuItem(value: e, child: Text(e.itemName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => setDialogState(() => _selectedImportItem = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _importQtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: StaffTheme.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                hintText: 'Số lượng',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                side: BorderSide(color: StaffTheme.primaryBlue.withOpacity(0.5)),
                              ),
                              child: const Text('HỦY', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _handleImport(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: StaffTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              child: const Text('XÁC NHẬN NHẬP KHO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(gradient: StaffTheme.primaryGradient),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BIỂU MẪU XUẤT HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: DistributionExportForm(
                  onSuccess: () {
                    Navigator.pop(ctx);
                    _loadData(); // Tải lại dữ liệu sau khi xuất hàng thành công
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWarehouseState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange.shade200),
          const SizedBox(height: 16),
          const Text('Bạn chưa được gán quản lý kho nào!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Vui lòng liên hệ Điều động viên.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showWarehouseQuickView(Warehouse w) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.warehouseName, style: StaffTheme.titleLarge.copyWith(color: StaffTheme.textDark)),
            Text(w.location, style: StaffTheme.cardSubtitle),
            const Divider(height: 30),
            const Text('Gợi ý: Nhấp để xem chi tiết tồn kho kho lân cận (Đang phát triển)'),
          ],
        ),
      ),
    );
  }
}

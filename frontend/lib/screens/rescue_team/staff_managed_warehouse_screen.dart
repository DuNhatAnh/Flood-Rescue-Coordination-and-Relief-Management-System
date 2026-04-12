import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/warehouse.dart';
import '../../models/assignment.dart';
import '../../models/inventory.dart';
import '../../services/warehouse_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/relief_item_service.dart';
import '../../models/relief_item.dart';
import '../../utils/staff_theme.dart';
import '../../models/vehicle.dart';
import 'distribution_export_screen.dart';
import '../../models/user_model.dart';


class StaffManagedWarehouseScreen extends StatefulWidget {
  const StaffManagedWarehouseScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagedWarehouseScreen> createState() => StaffManagedWarehouseScreenState();
}

class StaffManagedWarehouseScreenState extends State<StaffManagedWarehouseScreen> with SingleTickerProviderStateMixin {
  final WarehouseService _warehouseService = WarehouseService();
  final InventoryService _inventoryService = InventoryService();
  final VehicleService _vehicleService = VehicleService();
  final ReliefItemService _reliefItemService = ReliefItemService();
  
  late TabController _tabController;
  Warehouse? _myWarehouse; // Currently viewed warehouse
  String? _managedWarehouseId; // ID of the warehouse officially managed by the user
  List<Warehouse> _allWarehouses = [];
  List<Inventory> _inventory = [];
  List<Vehicle> _vehicles = [];
  List<ReliefItem> _reliefItems = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();

  // Form state cho Nhập hàng
  String? _importSource;
  ReliefItem? _selectedImportItem;
  final TextEditingController _importQtyController = TextEditingController();

  // Form state cho Thêm phương tiện
  final TextEditingController _plateController = TextEditingController();
  String? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    refreshData();
    
    // Kiểm tra xem có được mở từ màn hình Nhiệm vụ không
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('missionContext')) {
        _showExportDialog(
          mission: args['missionContext'] as Assignment,
          mode: args['mode'] as String
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importQtyController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() => _isLoading = true);
    try {
      final String? userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final managed = await _warehouseService.getByManagerId(userId);
      final all = await _warehouseService.getAll();

      // Chỉ lấy kho được Admin gán trực tiếp (theo managerId)
      Warehouse? currentWarehouse = managed;
      
      // Nếu không có kho gán riêng, nhưng là Admin thì mặc định lấy kho đầu tiên để xem
      if (currentWarehouse == null && AuthService.currentUser?.role == UserRole.admin) {
        if (all.isNotEmpty) currentWarehouse = all.first;
      }


      try {
        final itemData = await _reliefItemService.getAll();
        _reliefItems = itemData;
      } catch (e) {
        print('Error fetching items: $e');
      }

      setState(() {
        _myWarehouse = currentWarehouse;
        _managedWarehouseId = managed?.id;
        _allWarehouses = all;
      });

      if (currentWarehouse != null) {
        final results = await Future.wait([
          _inventoryService.getWarehouseInventory(currentWarehouse.id!),
          _vehicleService.getAllVehicles(warehouseId: currentWarehouse.id!),
        ]);
        
        setState(() {
          _inventory = results[0] as List<Inventory>;
          final vehicleResponse = results[1] as Map<String, dynamic>;
          final List vehicleList = vehicleResponse['content'] ?? [];
          _vehicles = vehicleList.map((v) => Vehicle.fromJson(v)).toList();
        });
      }
    } catch (e) {
      print('Error in _loadData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC THÊM PHƯƠNG TIỆN ---
  Future<void> _handleAddVehicle(BuildContext ctx) async {
    if (_selectedVehicleType == null || _plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ biển số và loại xe')));
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(ctx);

    try {
      // Giả sử API yêu cầu object: { vehicleType: string, licensePlate: string, status: "AVAILABLE" }
      await _vehicleService.createVehicle({
        'vehicleType': _selectedVehicleType,
        'licensePlate': _plateController.text.trim().toUpperCase(),
        'status': 'AVAILABLE',
        'warehouseId': _myWarehouse?.id,
        'teamId': AuthService.currentUser?.teamId, // Tự động gán cho đội của nhân viên đang tạo
      }, userId: AuthService.currentUser?.id ?? 'STAFF');
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm phương tiện thành công!'), backgroundColor: StaffTheme.successGreen));
      refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: StaffTheme.errorRed));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddVehicleDialog() {
    _selectedVehicleType = null;
    _plateController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(gradient: StaffTheme.primaryGradient, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ĐĂNG KÝ PHƯƠNG TIỆN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOẠI PHƯƠNG TIỆN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: StaffTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        hint: const Text('Chọn loại xe/xuồng'),
                        value: _selectedVehicleType,
                        items: ['Xe tải cứu trợ', 'Xe bán tải', 'Xuồng máy', 'Cano']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedVehicleType = val),
                      ),
                      const SizedBox(height: 20),
                      const Text('BIỂN KIỂM SOÁT / MÃ ĐỊNH DANH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'VD: 43A-123.45',
                          filled: true,
                          fillColor: StaffTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleAddVehicle(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StaffTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('XÁC NHẬN THÊM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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

  // --- 1. LOGIC XÓA PHƯƠNG TIỆN ---
  Future<void> _handleDeleteVehicle(String vehicleId) async {
    // Hiện thông báo xác nhận để tránh bấm nhầm
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn gỡ bỏ phương tiện này khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('HỦY', style: TextStyle(color: StaffTheme.textLight))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('XÓA NGAY', style: TextStyle(color: StaffTheme.errorRed, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      // Gọi service để xóa (Đảm bảo VehicleService đã có hàm deleteVehicle)
      await _vehicleService.deleteVehicle(vehicleId, userId: AuthService.currentUser?.id ?? 'STAFF');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa phương tiện thành công!'), backgroundColor: StaffTheme.successGreen)
      );
      refreshData(); // Tải lại danh sách mới
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: StaffTheme.errorRed)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIC CẬP NHẬT PHƯƠNG TIỆN ---
  Future<void> _handleUpdateVehicle(BuildContext ctx, String vehicleId) async {
    if (_selectedVehicleType == null || _plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng không để trống thông tin'))
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(ctx); // Đóng dialog

    try {
      await _vehicleService.updateVehicle(vehicleId, {
        'vehicleType': _selectedVehicleType,
        'licensePlate': _plateController.text.trim().toUpperCase(),
        'warehouseId': _myWarehouse?.id
      }, userId: AuthService.currentUser?.id ?? 'STAFF');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: StaffTheme.successGreen)
      );
      refreshData(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: StaffTheme.errorRed)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. DIALOG CHỈNH SỬA PHƯƠNG TIỆN ---
  void _showEditVehicleDialog(Vehicle vehicle) {
    // Đổ dữ liệu cũ vào các trường nhập liệu
    _selectedVehicleType = vehicle.vehicleType;
    _plateController.text = vehicle.licensePlate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: StaffTheme.primaryGradient, 
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CẬP NHẬT PHƯƠNG TIỆN', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOẠI PHƯƠNG TIỆN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: StaffTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        value: _selectedVehicleType,
                        items: ['Xe tải cứu trợ', 'Xe bán tải', 'Xuồng máy', 'Cano']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedVehicleType = val),
                      ),
                      const SizedBox(height: 20),
                      const Text('BIỂN KIỂM SOÁT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: StaffTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleUpdateVehicle(ctx, vehicle.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StaffTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('LƯU THAY ĐỔI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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

  @override
Widget build(BuildContext context) {
  if (_isLoading) return const Center(child: CircularProgressIndicator());
  
  return Scaffold(
    backgroundColor: StaffTheme.background,
    body: _myWarehouse == null 
      ? _buildNoWarehouseState()
      : LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildViewingModeBanner(),
                      _buildLowStockAlert(), // Thêm cảnh báo hàng sắp hết
                      _buildMapSection(height: 600),
                    ],
                  ),
                ),
              ),
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
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  if (_myWarehouse?.id != _managedWarehouseId)
                    SliverToBoxAdapter(child: _buildViewingModeBanner()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildLowStockAlert(),
                          const SizedBox(height: 10),
                          _buildMapSection(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: StaffTheme.border),
                        boxShadow: StaffTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          _buildInventoryHeader(),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  ),
                  // Hiển thị danh sách dựa theo tab đang chọn (0: Hàng hóa, 1: Phương tiện)
                  _tabController.index == 0 
                    ? _buildInventoryList(isScrollable: false)
                    : _buildVehicleList(isScrollable: false),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              // Đưa nút hành động xuống dưới cùng màn hình trong Stack
              Positioned(
                bottom: 0, 
                left: 0, 
                right: 0, 
                child: _buildBottomActionButtons()
              ),
            ],
          );
        }
      },
    ),

    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}


  void _selectWarehouse(Warehouse w) async {
    if (w.id == _myWarehouse?.id) return;
    
    setState(() {
      _isLoading = true;
      _myWarehouse = w;
      _inventory = [];
      _vehicles = [];
    });

    try {
      final results = await Future.wait([
        _inventoryService.getWarehouseInventory(w.id!),
        _vehicleService.getAllVehicles(warehouseId: w.id!),
      ]);

      setState(() {
        _inventory = results[0] as List<Inventory>;
        final vehicleResponse = results[1] as Map<String, dynamic>;
        final List vehicleList = vehicleResponse['content'] ?? [];
        _vehicles = vehicleList.map((v) => Vehicle.fromJson(v)).toList();
        _isLoading = false;
      });
      
      // Di chuyển bản đồ tới kho mới
      if (w.latitude != null && w.longitude != null) {
        _mapController.move(LatLng(w.latitude!, w.longitude!), 14.5);
      }
    } catch (e) {
      print('Error switching warehouse: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMapSection({double height = 400}) {
    // Tọa độ trung tâm mặc định (Đà Nẵng) nếu không có kho nào chọn
    final LatLng defaultCenter = const LatLng(16.0544, 108.2023);
    final LatLng center = (_myWarehouse?.latitude != null && _myWarehouse?.longitude != null)
        ? LatLng(_myWarehouse!.latitude!, _myWarehouse!.longitude!)
        : defaultCenter;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StaffTheme.border),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: StaffTheme.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_myWarehouse?.warehouseName ?? 'Kho'} - ${_myWarehouse?.location ?? 'Đang xác định vị trí...'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StaffTheme.primaryBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'vn.rescue.core',
                  ),
                  MarkerLayer(
                    markers: _allWarehouses.map((w) {
                      final bool isSelected = w.id == _myWarehouse?.id;
                      final bool isManagedByMe = w.id == _managedWarehouseId;
                      
                      // Sử dụng tọa độ thật của kho, nếu không có thì xê dịch nhẹ quanh tâm để không bị đè lên nhau hoàn toàn
                      final LatLng point = (w.latitude != null && w.longitude != null)
                          ? LatLng(w.latitude!, w.longitude!)
                          : LatLng(
                              defaultCenter.latitude + (int.parse(w.id?.substring(w.id!.length - 2) ?? '0', radix: 16) % 10 - 5) * 0.002,
                              defaultCenter.longitude + (int.parse(w.id?.substring(w.id!.length - 4, w.id!.length - 2) ?? '0', radix: 16) % 10 - 5) * 0.002,
                            );

                      return Marker(
                        point: point,
                        width: isSelected ? 100 : 40,
                        height: isSelected ? 70 : 40,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => _selectWarehouse(w),
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: isSelected 
                                    ? Colors.red // Kho đang chọn
                                    : (isManagedByMe ? Colors.orange : StaffTheme.primaryBlue), // Cam: Kho của mình, Xanh: Kho lân cận
                                size: isSelected ? 40 : 30,
                              ),
                              if (isSelected) 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red, width: 0.5)),
                                  child: Text(w.warehouseName, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryHeader() {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'DANH MỤC QUẢN LÝ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: StaffTheme.textMedium,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              // Badge số lượng (Luôn hiển thị)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StaffTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_inventory.length} hàng, ${_vehicles.length} xe',
                  style: const TextStyle(color: StaffTheme.textLight, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              // AnimatedBuilder cho nút THÊM XE (Chỉ hiện ở tab Phương tiện)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  if (_tabController.index == 1) {
                    return SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: _showAddVehicleDialog,
                        icon: const Icon(Icons.add_circle, size: 16, color: Colors.white),
                        label: const Text(
                          "THÊM XE",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StaffTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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
          // Lắng nghe sự kiện tap để UI update ngay lập tức
          onTap: (index) => setState(() {}), 
          tabs: const [
            Tab(child: Text('HÀNG HÓA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Tab(child: Text('PHƯƠNG TIỆN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
      ],
    ),
  );
}

  dynamic _buildVehicleList({required bool isScrollable}) {
    if (isScrollable && _vehicles.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Không có phương tiện nào', style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: _showAddVehicleDialog, child: const Text('Thêm phương tiện mới'))
        ],
      );
    }

    // Phần build từng item trong danh sách
    final itemBuilder = (context, index) {
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
            // Icon xe
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: StaffTheme.background, borderRadius: BorderRadius.circular(10)),
              child: Icon(_getVehicleIcon(vehicle.vehicleType), color: StaffTheme.primaryBlue, size: 30),
            ),
            const SizedBox(width: 15),
            
            // Thông tin xe (Dùng Expanded để chiếm phần không gian ở giữa)
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

            // --- VỊ TRÍ THÊM NÚT SỬA & XÓA Ở ĐÂY ---
            const SizedBox(width: 10), // Khoảng cách giữa thông tin và nút bấm
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact, // Thu nhỏ diện tích icon để tiết kiệm không gian
                  icon: const Icon(Icons.edit_rounded, color: StaffTheme.primaryBlue, size: 22),
                  onPressed: () => _showEditVehicleDialog(vehicle),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, color: StaffTheme.errorRed, size: 22),
                  onPressed: () => _handleDeleteVehicle(vehicle.id),
                  tooltip: 'Xóa xe',
                ),
              ],
            ),
            // ---------------------------------------
          ],
        ),
      );
    };

    // Trả về ListView tùy theo thiết kế của bạn (Sliver hoặc Scrollable)
    if (isScrollable) {
      return ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: itemBuilder,
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: _vehicles.length,
        ),
      );
    }
  }

  IconData _getVehicleIcon(String type) {
    if (type.contains('Xuồng') || type.contains('Cano')) return Icons.directions_boat_filled_rounded;
    if (type.contains('Xe tải')) return Icons.local_shipping_rounded;
    if (type.contains('Xe bán tải')) return Icons.directions_car_filled_rounded;
    return Icons.local_shipping;
  }

  dynamic _buildInventoryList({required bool isScrollable}) {
    final content = (context, index) {
      final item = _inventory[index];
      final bool isLowStock = item.status == 'LOW_STOCK'; 
      final int threshold = item.minThreshold ?? 100;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isLowStock ? StaffTheme.errorRed.withOpacity(0.5) : StaffTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
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
                          value: (item.quantity / (threshold * 2)).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade100,
                          color: isLowStock ? StaffTheme.errorRed : StaffTheme.successGreen,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.w900, color: isLowStock ? StaffTheme.errorRed : StaffTheme.textMedium)),
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


  Widget _buildViewingModeBanner() {
    if (_myWarehouse?.id == _managedWarehouseId) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E), // Deep indigo for viewing mode
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHẾ ĐỘ XEM LÂN CẬN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text('Bạn đang xem thông tin kho của đội khác.', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          TextButton(
            onPressed: refreshData, 
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('QUAY LẠI KHO CỦA TÔI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    final lowStockItems = _inventory.where((it) => it.status == 'LOW_STOCK').toList();
    if (lowStockItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StaffTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: StaffTheme.errorRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: StaffTheme.errorRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'CẢNH BÁO: CÓ ${lowStockItems.length} MẶT HÀNG SẮP HẾT!',
                style: const TextStyle(color: StaffTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: lowStockItems.take(3).map((it) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StaffTheme.errorRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${it.itemName}: ${it.quantity}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
          if (lowStockItems.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('... và ${lowStockItems.length - 3} mặt hàng khác', style: const TextStyle(color: StaffTheme.errorRed, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    // Chỉ hiển thị ở tab Hàng hóa (Index 0)
    if (_tabController.index != 0) return const SizedBox.shrink();
    
    final bool isExternal = _myWarehouse?.id != _managedWarehouseId;
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isExternal ? null : () => _showImportDialog(),
              icon: Icon(Icons.add_shopping_cart_rounded, color: isExternal ? Colors.white54 : Colors.white),
              label: Text('NHẬP HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: isExternal ? Colors.white54 : Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExternal ? Colors.grey : StaffTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isExternal ? null : () => _showExportDialog(),
              icon: Icon(Icons.outbox_rounded, color: isExternal ? Colors.white54 : Colors.white),
              label: Text('XUẤT HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: isExternal ? Colors.white54 : Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExternal ? Colors.grey : const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---
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

    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận nhập kho?', style: TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
        content: Text('Bạn chắc chắn muốn nhập ${qty} ${_selectedImportItem!.unit} ${_selectedImportItem!.itemName} từ nguồn "${_importSource}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx2);
              setState(() => _isLoading = true);
              Navigator.pop(ctx);

              try {
                await _inventoryService.importStock(
                  _myWarehouse!.id!,
                  _selectedImportItem!.id!,
                  qty,
                  userId: AuthService.currentUser?.id,
                  source: _importSource,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập kho thành công!'), backgroundColor: StaffTheme.successGreen));
                refreshData(); 
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: StaffTheme.errorRed));
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  void _showImportDialog() {
    _importSource = null;
    _selectedImportItem = null;
    _importQtyController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(gradient: StaffTheme.primaryGradient, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BIỂU MẪU NHẬP HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. THÔNG TIN NGUỒN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(filled: true, fillColor: StaffTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        hint: const Text('Chọn nguồn cung cấp'),
                        value: _importSource,
                        items: ['Cứu trợ Trung ương', 'Mạnh thường quân', 'Điều chuyển từ kho khác', 'Nhập khẩu hỗ trợ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setDialogState(() => _importSource = val),
                      ),
                      const SizedBox(height: 20),
                      const Text('2. CHI TIẾT LÔ HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<ReliefItem>(
                              isExpanded: true,
                              decoration: InputDecoration(filled: true, fillColor: StaffTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), hintText: 'Tên hàng'),
                              value: _selectedImportItem,
                              items: _reliefItems.map((e) => DropdownMenuItem(value: e, child: Text(e.itemName))).toList(),
                              onChanged: (val) => setDialogState(() => _selectedImportItem = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(controller: _importQtyController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: StaffTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), hintText: 'Số lượng')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _handleImport(ctx), style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('XÁC NHẬN NHẬP KHO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
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

  void _showExportDialog({Assignment? mission, String? mode}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900), // Rộng hơn để chứa bảng đối chiếu
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(gradient: StaffTheme.primaryGradient, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mission != null ? 'XUẤT KHO THEO NHIỆM VỤ' : 'BIỂU MẪU XUẤT HÀNG', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng dialog
                        if (mission != null) {
                          // Nếu đang trong luồng Nhiệm vụ, tự động quay về màn hình Nhiệm vụ
                          Navigator.pop(context); 
                        }
                      }, 
                      icon: const Icon(Icons.close, color: Colors.white)
                    ),
                  ],
                ),
              ),
              Flexible(child: DistributionExportForm(
                mission: mission,
                mode: mode,
                onSuccess: () { 
                  Navigator.pop(ctx); // Đóng dialog form
                  if (mission != null) {
                    // Nếu đang trong luồng Nhiệm vụ, tự động quay về màn hình Nhiệm vụ
                    Navigator.pop(context); 
                  } else {
                    refreshData(); // Nếu ở kho bình thường thì tải lại data
                  }
                }
              )),
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
}
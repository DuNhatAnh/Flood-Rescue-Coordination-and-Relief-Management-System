import 'package:flutter/material.dart';
import '../../models/assignment.dart';
import '../../models/inventory.dart';
import '../../models/warehouse.dart';
import '../../services/distribution_service.dart';
import '../../services/inventory_service.dart';
import '../../services/rescue_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/auth_service.dart';
import '../../utils/staff_theme.dart';
import '../../models/user_model.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';

class DistributionExportScreen extends StatelessWidget {
  const DistributionExportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: Text('XUẤT HÀNG CỨU TRỢ', style: StaffTheme.titleLarge),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const DistributionExportForm(),
    );
  }
}

class DistributionExportForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Assignment? mission;
  final String? mode; // 'MANUAL' or 'QUICK'
  const DistributionExportForm({Key? key, this.onSuccess, this.mission, this.mode}) : super(key: key);

  @override
  State<DistributionExportForm> createState() => _DistributionExportFormState();
}

class _DistributionExportFormState extends State<DistributionExportForm> {
  final DistributionService _distService = DistributionService();
  final RescueService _rescueService = RescueService();
  final WarehouseService _warehouseService = WarehouseService();
  final InventoryService _inventoryService = InventoryService();
  final VehicleService _vehicleService = VehicleService();

  List<Assignment> _myTasks = [];
  List<Warehouse> _warehouses = [];
  List<Inventory> _currentInventory = [];
  List<Vehicle> _availableVehicles = [];
  
  Assignment? _selectedTask;
  Warehouse? _selectedWarehouse;
  Warehouse? _myManagedWarehouse; // KHO CỐ ĐỊNH CỦA ĐỘI (VD: Xuân Hòa)
  Vehicle? _selectedVehicle;
  final TextEditingController _changeReasonController = TextEditingController();
  
  List<Map<String, dynamic>> _selectedItems = [];
  bool _isLoading = true;
  String _exportType = 'EXPORT'; 
  Warehouse? _destinationWarehouse;
  bool _vehicleStepConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final tasks = await _rescueService.getMyTasks();
    final warehouses = await _warehouseService.getAll();
    
    Warehouse? myWarehouse;
    // HỢP NHẤT: Thử lấy kho cố định của Manager HOẶC kho của Nhiệm vụ hiện tại
    final String? currentUserId = AuthService.currentUser?.id;
    if (currentUserId != null) {
       // Thử lấy qua WarehouseService (fixed API)
       final managedWh = await _warehouseService.getByManagerId(currentUserId);
       if (managedWh != null) {
         myWarehouse = warehouses.firstWhere((w) => w.id == managedWh.id, orElse: () => managedWh);
       } else {
         // Thử qua RescueService (dùng manager ID)
         final whMap = await _rescueService.getWarehouseByManager(currentUserId);
         if (whMap != null) {
            final whId = (whMap['id'] ?? whMap['_id']).toString();
            myWarehouse = warehouses.firstWhere((w) => w.id == whId, orElse: () => Warehouse.fromJson(whMap));
         }
       }
    }

    if (mounted) {
      setState(() {
        _myTasks = tasks;
        _warehouses = warehouses;
        _isLoading = false;
        _myManagedWarehouse = myWarehouse;
        
        if (widget.mission != null) {
          _selectedTask = tasks.firstWhere((t) => t.id == widget.mission!.id, orElse: () => widget.mission!);
          _exportType = 'EXPORT';
        }

        if (myWarehouse != null) {
          _selectedWarehouse = myWarehouse; // Mặc định kho xuất là kho của mình (FIX KHO CỦA TÔI)
          _onWarehouseChanged(myWarehouse);
        } else if (widget.mission != null) {
          // Nếu không tìm thấy kho của Manager, tìm theo tên "Xuân Hòa" nếu có (Dự phòng)
          try {
             final xuanHoa = warehouses.firstWhere((w) => w.warehouseName.contains('Xuân Hòa'));
             _selectedWarehouse = xuanHoa;
             _onWarehouseChanged(xuanHoa);
          } catch (_) {
             if (warehouses.isNotEmpty) _onWarehouseChanged(warehouses.first);
          }
        }
      });
    }
  }

  // LOGIC CHUYỂN ĐỔI LOẠI HÌNH THEO YÊU CẦU CỐ ĐỊNH KHO
  void _toggleExportType(String type) {
    if (_exportType == type) return;

    setState(() {
      _exportType = type;
      _selectedItems = [];
      _currentInventory = [];
      
      if (type == 'EXPORT') {
        // XUẤT CỨU TRỢ: Kho xuất hàng = Kho Xuân Hòa (Cố định)
        _selectedWarehouse = _myManagedWarehouse;
        _destinationWarehouse = null;
        if (_myManagedWarehouse != null) _onWarehouseChanged(_myManagedWarehouse);
      } else {
        // ĐIỀU CHUYỂN: Kho đích = Kho Xuân Hòa (Cố định), Kho xuất = Tự chọn kho khác
        _destinationWarehouse = _myManagedWarehouse;
        _selectedWarehouse = null; // Để người dùng tự chọn kho nguồn khác
      }
    });
  }

  Future<void> _loadVehicles(String warehouseId) async {
    final vehiclesRaw = await _vehicleService.getAvailableVehicles();
    final vehicles = vehiclesRaw.map((v) => Vehicle.fromJson(v)).toList();
    // Filter vehicles by team's locality or warehouse if applicable (simplified here)
    if (mounted) setState(() => _availableVehicles = vehicles);
  }

  Future<void> _onWarehouseChanged(Warehouse? wh) async {
    if (wh == null) return;
    setState(() {
      _selectedWarehouse = wh;
      _currentInventory = [];
      _selectedItems = [];
    });
    
    final inv = await _inventoryService.getWarehouseInventory(wh.id!);
    _loadVehicles(wh.id!);

    if (mounted) {
      setState(() {
        _currentInventory = inv;
        
        // AUTO-FILL FOR QUICK MODE (Fix Hình 1: Không hiện danh sách)
        if (widget.mode == 'QUICK' && widget.mission != null) {
          // HỢP NHẤT: missionItems + assignedItems
          final reqItems = {
            ...{for (var i in widget.mission!.assignedItems) i.itemId: i},
            ...{for (var i in widget.mission!.missionItems) i.itemId: i}
          }.values;

          for (var item in reqItems) {
            final stock = inv.firstWhere((s) => s.itemId == item.itemId, orElse: () => Inventory(warehouseId: _selectedWarehouse!.id!, itemId: item.itemId, itemName: item.itemName, quantity: 0, unit: item.unit));
            _selectedItems.add({
              'itemId': item.itemId,
              'itemName': item.itemName,
              'quantity': item.quantity,
              'unit': item.unit,
              'stock': stock.quantity,
            });
          }
        }
      });
    }
  }

  void _addItem() async {
    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn kho trước')));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        Inventory? selectedInv;
        final qtyController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Thêm vật phẩm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Inventory>(
                  decoration: const InputDecoration(labelText: 'Vật phẩm trong kho'),
                  items: _currentInventory.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text('${e.itemName} (Tồn: ${e.quantity})'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedInv = val),
                ),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng xuất'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  if (selectedInv == null) return;
                  final q = int.tryParse(qtyController.text) ?? 0;
                  if (q <= 0 || q > selectedInv!.quantity) return;
                  
                  Navigator.pop(context, {
                    'itemId': selectedInv!.itemId,
                    'itemName': selectedInv!.itemName,
                    'quantity': q,
                  });
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
        );
      }
    );

    if (result != null) {
      setState(() {
        final existingIndex = _selectedItems.indexWhere((item) => item['itemId'] == result['itemId']);
        if (existingIndex != -1) {
          // GỘP HÀNG: Cộng dồn nếu đã có vật phẩm này
          _selectedItems[existingIndex]['quantity'] += result['quantity'];
        } else {
          result['stock'] = _currentInventory.firstWhere((e) => e.itemId == result['itemId']).quantity;
          _selectedItems.add(result);
        }
      });
    }
  }

  void _editItem(Map<String, dynamic> item) async {
    final qtyController = TextEditingController(text: item['quantity'].toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa số lượng: ${item['itemName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tồn kho hiện tại: ${item['stock']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Số lượng mới', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final q = int.tryParse(qtyController.text) ?? 0;
              if (q <= 0 || q > item['stock']) return;
              Navigator.pop(context, q);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        item['quantity'] = result;
      });
    }
  }

  Future<void> _submit() async {
    if ((_exportType == 'EXPORT' && _selectedTask == null) || 
        (_exportType == 'TRANSFER' && _destinationWarehouse == null) ||
        _selectedWarehouse == null || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin')));
      return;
    }

    // Hiển thị hộp thoại xác nhận trước khi thực hiện
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xuất kho?', style: TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn chắc chắn muốn thực hiện phiếu ${_exportType == 'EXPORT' ? 'xuất cứu trợ' : 'điều chuyển'} này?'),
            const SizedBox(height: 12),
            const Text('Danh sách vật phẩm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ..._selectedItems.map((item) => Text('• ${item['quantity']} ${item['itemName']}', style: const TextStyle(fontSize: 13))).toList(),
            if (_selectedVehicle != null) ...[
              const SizedBox(height: 8),
              Text('Phương tiện: ${_selectedVehicle!.licensePlate}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    // Nếu có đổi xe (kiểm tra xem xe đã chọn có nằm trong danh sách xe được gán không)
    bool isDifferentVehicle = _selectedVehicle != null && 
        !(widget.mission?.vehicleIds?.contains(_selectedVehicle!.id) ?? false);
        
    if (widget.mission != null && isDifferentVehicle) {
       await _rescueService.updateAssignmentVehicle(
         widget.mission!.id, 
         _selectedVehicle!.id!, 
         _changeReasonController.text.isNotEmpty ? _changeReasonController.text : "Đội cứu hộ chủ động đổi xe tại kho"
       );
    }

    final success = await _distService.createDistribution(
      _selectedWarehouse!.id!,
      _exportType == 'EXPORT' ? _selectedTask?.id : null,
      _selectedItems,
      type: _exportType,
      destinationWarehouseId: _exportType == 'TRANSFER' ? _destinationWarehouse?.id : null,
    );
    
    setState(() => _isLoading = false);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xuất hàng thành công!'), backgroundColor: StaffTheme.successGreen));
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi xuất hàng'), backgroundColor: StaffTheme.errorRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. LOẠI HÌNH'),
          _buildCard(
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Xuất cứu trợ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: 'EXPORT',
                    groupValue: _exportType,
                    dense: true,
                    onChanged: (val) => _toggleExportType(val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Điều chuyển', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: 'TRANSFER',
                    groupValue: _exportType,
                    dense: true,
                    onChanged: (val) => _toggleExportType(val!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          if (_exportType == 'EXPORT' && widget.mission == null) ...[
            _buildSectionTitle('2. CHỌN NHIỆM VỤ'),
            _buildCard(
              child: DropdownButtonFormField<Assignment>(
                hint: const Text('Chọn nhiệm vụ được giao'),
                value: _selectedTask,
                isExpanded: true,
                items: _myTasks.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text('Nhiệm vụ #${e.id.toString().substring(0,4)}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedTask = val),
              ),
            ),
          ] else if (_exportType == 'TRANSFER') ...[
            _buildSectionTitle(_exportType == 'TRANSFER' ? '2. KHO TIẾP NHẬN (CỐ ĐỊNH)' : '2. CHỌN KHO ĐÍCH'),
            _buildCard(
              child: DropdownButtonFormField<Warehouse>(
                hint: const Text('Kho mặc định của bạn'),
                value: _destinationWarehouse,
                isExpanded: true,
                items: _warehouses
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.warehouseName),
                )).toList(),
                // Nếu là Điều chuyển thì Kho đích cố định là kho Xuân Hòa của bạn
                onChanged: (_exportType == 'TRANSFER') ? null : (val) => setState(() => _destinationWarehouse = val),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          _buildSectionTitle(_exportType == 'EXPORT' ? '3. KHO XUẤT HÀNG (CỐ ĐỊNH)' : '3. CHỌN KHO XUẤT HÀNG'),
          _buildCard(
            child: DropdownButtonFormField<Warehouse>(
              hint: const Text('Chọn kho hàng'),
              value: _selectedWarehouse,
              isExpanded: true,
              items: _warehouses
                  .where((w) => _exportType != 'TRANSFER' || w.id != _myManagedWarehouse?.id)
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.warehouseName),
              )).toList(),
              // Nếu là Xuất cứu trợ thì Kho xuất cố định là kho của đội
              onChanged: (_exportType == 'EXPORT') 
                  ? null 
                  : _onWarehouseChanged, 
            ),
          ),

          if (widget.mission != null) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('4. PHƯƠNG TIỆN DI CHUYỂN'),
            _buildCard(
              child: Column(
                children: [
                   DropdownButtonFormField<Vehicle>(
                      decoration: const InputDecoration(labelText: 'Chọn xe sử dụng', border: InputBorder.none),
                      hint: const Text('Giữ nguyên xe điều phối gán'),
                      value: _selectedVehicle,
                      items: _availableVehicles.map((v) => DropdownMenuItem(
                        value: v,
                        child: Text('${v.vehicleType} - ${v.licensePlate}'),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedVehicle = val),
                   ),
                   if (_selectedVehicle != null && !(widget.mission?.vehicleIds?.contains(_selectedVehicle?.id) ?? false))
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: TextField(
                         controller: _changeReasonController,
                         decoration: const InputDecoration(
                           labelText: 'Lý do đổi xe (bắt buộc)',
                           hintText: 'VD: Xe cũ hỏng, xe này tải trọng lớn hơn...',
                           labelStyle: TextStyle(fontSize: 12),
                         ),
                       ),
                     ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(
                 flex: 3,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(widget.mission != null ? '5. DANH SÁCH XUẤT KHO' : '4. DANH SÁCH VẬT PHẨM'),
                          if (widget.mode != 'QUICK')
                            TextButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text('Thêm hàng', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      ..._selectedItems.map((item) => _buildItemTile(item)).toList(),
                      if (_selectedItems.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Chưa có vật phẩm nào được chọn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )),
                   ],
                 ),
               ),
                if (widget.mission != null && widget.mode == 'MANUAL') ...[
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         _buildSectionTitle('ĐỐI CHIẾU YÊU CẦU'),
                         // HỢP NHẤT: missionItems + assignedItems (Fix Hình 2: Không hiện danh sách đối chiếu)
                         ...{
                           ...{for (var i in widget.mission!.assignedItems) i.itemId: i},
                           ...{for (var i in widget.mission!.missionItems) i.itemId: i}
                         }.values.map((req) {
                             final selected = _selectedItems.firstWhere((s) => s['itemId'] == req.itemId, orElse: () => {});
                             final isMatch = selected.isNotEmpty && selected['quantity'] == req.quantity;
                             return _buildComparisonItem('${req.quantity} ${req.itemName}', isMatch);
                         }).toList(),
                         if (widget.mission?.licensePlate != null) ...[
                            const SizedBox(height: 12),
                            const Text('PHƯƠNG TIỆN ĐÃ GIAO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: StaffTheme.textLight)),
                            const SizedBox(height: 4),
                            _buildComparisonItem(widget.mission!.licensePlate!, _selectedVehicle?.licensePlate == widget.mission!.licensePlate || _selectedVehicle == null),
                         ],
                      ],
                    ),
                  ),
               ],
            ],
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text('XÁC NHẬN XUẤT KHO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String text, bool isMatch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMatch ? StaffTheme.successGreen.withOpacity(0.1) : StaffTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMatch ? StaffTheme.successGreen.withOpacity(0.3) : StaffTheme.border),
      ),
      child: Row(
        children: [
          Icon(isMatch ? Icons.check_circle : Icons.pending_outlined, 
               color: isMatch ? StaffTheme.successGreen : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: isMatch ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight, letterSpacing: 1.1)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: StaffTheme.border),
      ),
      child: child,
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    bool isWarning = false;
    bool isSuccess = false;
    
    if (widget.mission != null) {
      // HỢP NHẤT: Tìm trong danh sách yêu cầu tổng hợp
      final allReqs = [
        ...widget.mission!.assignedItems,
        ...widget.mission!.missionItems
      ];
      final req = allReqs.firstWhere((r) => r.itemId == item['itemId'], orElse: () => MissionItem(itemId: '', itemName: '', unit: '', quantity: 0));
      if (req.itemId.isNotEmpty) {
        if (item['quantity'] == req.quantity) isSuccess = true;
        if (item['quantity'] > item['stock']) isWarning = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWarning ? StaffTheme.errorRed : (isSuccess ? StaffTheme.successGreen : StaffTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isSuccess) const Icon(Icons.check_circle, color: StaffTheme.successGreen, size: 18),
              if (isWarning) const Icon(Icons.warning_amber_rounded, color: StaffTheme.errorRed, size: 18),
              if (isSuccess || isWarning) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Số lượng: ${item['quantity']}', style: StaffTheme.cardSubtitle),
                  if (item['quantity'] > item['stock'])
                    Text('Vượt mức tồn kho (${item['stock']})', style: const TextStyle(color: StaffTheme.errorRed, fontSize: 10)),
                ],
              ),
            ],
          ),
          if (widget.mode != 'QUICK')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: StaffTheme.primaryBlue, size: 20),
                  onPressed: () => _editItem(item),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: StaffTheme.errorRed, size: 20),
                  onPressed: () => setState(() => _selectedItems.remove(item)),
                  tooltip: 'Xóa',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

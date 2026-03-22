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
  const DistributionExportForm({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<DistributionExportForm> createState() => _DistributionExportFormState();
}

class _DistributionExportFormState extends State<DistributionExportForm> {
  final DistributionService _distService = DistributionService();
  final RescueService _rescueService = RescueService();
  final WarehouseService _warehouseService = WarehouseService();
  final InventoryService _inventoryService = InventoryService();

  List<Assignment> _myTasks = [];
  List<Warehouse> _warehouses = [];
  List<Inventory> _currentInventory = [];
  
  Assignment? _selectedTask;
  Warehouse? _selectedWarehouse;
  
  List<Map<String, dynamic>> _selectedItems = [];
  bool _isLoading = true;
  String _exportType = 'EXPORT'; 
  Warehouse? _destinationWarehouse;

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
    if (AuthService.currentUser?.role == UserRole.rescueStaff) {
       final managedWh = await _warehouseService.getByManagerId(AuthService.currentUser!.id);
       if (managedWh != null) {
         myWarehouse = warehouses.firstWhere((w) => w.id == managedWh.id, orElse: () => managedWh);
       }
    }

    if (mounted) {
      setState(() {
        _myTasks = tasks;
        _warehouses = warehouses;
        _isLoading = false;
        if (myWarehouse != null) {
          _onWarehouseChanged(myWarehouse);
        }
      });
    }
  }

  Future<void> _onWarehouseChanged(Warehouse? wh) async {
    if (wh == null) return;
    setState(() {
      _selectedWarehouse = wh;
      _currentInventory = [];
      _selectedItems = [];
    });
    
    final inv = await _inventoryService.getWarehouseInventory(wh.id!);
    if (mounted) setState(() => _currentInventory = inv);
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
        _selectedItems.add(result);
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

    setState(() => _isLoading = true);
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
                    onChanged: (val) => setState(() => _exportType = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Điều chuyển', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: 'TRANSFER',
                    groupValue: _exportType,
                    dense: true,
                    onChanged: (val) => setState(() => _exportType = val!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          if (_exportType == 'EXPORT') ...[
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
          ] else ...[
            _buildSectionTitle('2. CHỌN KHO ĐÍCH'),
            _buildCard(
              child: DropdownButtonFormField<Warehouse>(
                hint: const Text('Chọn kho tiếp nhận'),
                value: _destinationWarehouse,
                isExpanded: true,
                items: _warehouses
                    .where((w) => w.id != _selectedWarehouse?.id)
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.warehouseName),
                )).toList(),
                onChanged: (val) => setState(() => _destinationWarehouse = val),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          _buildSectionTitle('3. KHO XUẤT HÀNG'),
          _buildCard(
            child: DropdownButtonFormField<Warehouse>(
              hint: const Text('Chọn kho hàng'),
              value: _selectedWarehouse,
              isExpanded: true,
              items: _warehouses.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.warehouseName),
              )).toList(),
              onChanged: (AuthService.currentUser?.role == UserRole.admin) 
                  ? _onWarehouseChanged 
                  : null, 
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('4. DANH SÁCH VẬT PHẨM'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Số lượng: ${item['quantity']}', style: StaffTheme.cardSubtitle),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: StaffTheme.errorRed, size: 20),
            onPressed: () => setState(() => _selectedItems.remove(item)),
          ),
        ],
      ),
    );
  }
}

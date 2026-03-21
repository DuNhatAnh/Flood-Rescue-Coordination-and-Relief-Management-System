import 'package:flutter/material.dart';
import '../../models/inventory.dart';
import '../../models/warehouse.dart';
import '../../models/relief_item.dart';
import '../../services/inventory_service.dart';
import '../../services/relief_item_service.dart';
import '../../utils/staff_theme.dart';

class WarehouseInventoryScreen extends StatefulWidget {
  final Warehouse warehouse;
  const WarehouseInventoryScreen({Key? key, required this.warehouse}) : super(key: key);

  @override
  _WarehouseInventoryScreenState createState() => _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ReliefItemService _itemService = ReliefItemService();
  
  List<Inventory> _inventoryList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInventory();
  }

  Future<void> loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final list = await _inventoryService.getWarehouseInventory(widget.warehouse.id!);
      setState(() {
        _inventoryList = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải tồn kho: $e'), backgroundColor: StaffTheme.errorRed),
        );
      }
    }
  }

  void showImportDialog() async {
    final items = await _itemService.getAll();
    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có danh mục vật phẩm nào. Vui lòng thêm vật phẩm trước.')),
        );
      }
      return;
    }

    ReliefItem? selectedItem = items.first;
    final quantityController = TextEditingController();
    final sourceController = TextEditingController();
    final referenceController = TextEditingController();
    DateTime? expiryDate;
    String? selectedCondition = 'Mới (100%)';

    final conditions = ['Mới (100%)', 'Tối (Đã qua sử dụng)', 'Cũ', 'Cần thanh lý'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StaffTheme.cardRadius)),
          title: Text('Nhập hàng vào kho', style: StaffTheme.cardTitle),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                DropdownButtonFormField<ReliefItem>(
                  value: selectedItem,
                  decoration: InputDecoration(
                    labelText: 'Chọn loại hàng',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: items.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text('${item.itemName} (${item.unit})'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedItem = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số lượng',
                          hintText: 'VD: 100, 500...',
                          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                          prefixIcon: const Icon(Icons.add_shopping_cart_rounded, color: StaffTheme.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedCondition,
                        decoration: InputDecoration(
                          labelText: 'Tình trạng',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCondition = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Nguồn hàng (Cá nhân/Tổ chức)',
                    hintText: 'VD: Hội Chữ Thập Đỏ, Mạnh thường quân...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                    prefixIcon: const Icon(Icons.business_rounded, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  decoration: InputDecoration(
                    labelText: 'Số hiệu phiếu / Hóa đơn',
                    hintText: 'VD: PN-001, HĐ-123...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setDialogState(() => expiryDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: StaffTheme.primaryBlue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          expiryDate == null 
                            ? 'Chọn Hạn sử dụng (nếu có)' 
                            : 'HSD: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}',
                          style: TextStyle(color: expiryDate == null ? Colors.grey.shade600 : Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: StaffTheme.textLight))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final qty = int.tryParse(quantityController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số lượng hợp lệ')));
                  return;
                }

                try {
                  await _inventoryService.importStock(
                    widget.warehouse.id!,
                    selectedItem!.id!,
                    qty,
                    source: sourceController.text,
                    referenceNumber: referenceController.text,
                    expiryDate: expiryDate,
                    condition: selectedCondition,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    loadInventory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nhập hàng thành công!'), backgroundColor: StaffTheme.successGreen),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: StaffTheme.errorRed),
                    );
                  }
                }
              },
              child: const Text('Xác nhận nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: Text(widget.warehouse.warehouseName, style: StaffTheme.titleLarge),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StaffTheme.primaryBlue))
          : _inventoryList.isEmpty
              ? _buildEmptyInventory()
              : _buildInventoryList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showImportDialog,
        backgroundColor: StaffTheme.primaryBlue,
        elevation: 4,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text('NHẬP HÀNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('Kho hiện tại trống', style: StaffTheme.cardTitle.copyWith(color: StaffTheme.textLight)),
          Text('Nhấn nút "Nhập hàng" để bắt đầu', style: StaffTheme.cardSubtitle),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _inventoryList.length,
      itemBuilder: (context, index) {
        final inv = _inventoryList[index];
        final itemColor = _getItemColor(inv.itemName);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StaffTheme.border),
            boxShadow: StaffTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Professional 64x64 Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: inv.imageUrl != null
                        ? Image.network(
                            'http://localhost:8080${inv.imageUrl}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Icon(_getItemIcon(inv.itemName), color: itemColor.withOpacity(0.5), size: 30),
                          )
                        : Icon(_getItemIcon(inv.itemName), color: itemColor.withOpacity(0.5), size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                // Ledger Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.itemName.toUpperCase(),
                        style: StaffTheme.cardTitle.copyWith(fontSize: 14, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tồn kho hiện tại',
                        style: StaffTheme.cardSubtitle.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Specialized Stock Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${inv.quantity}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: itemColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inv.unit.toUpperCase(),
                        style: TextStyle(
                          color: itemColor.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getItemIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('gạo')) return Icons.bakery_dining_rounded;
    if (n.contains('nước')) return Icons.water_drop_rounded;
    if (n.contains('mì')) return Icons.ramen_dining_rounded;
    if (n.contains('áo phao')) return Icons.help_center_rounded;
    if (n.contains('thuốc') || n.contains('y tế')) return Icons.medication_rounded;
    if (n.contains('sữa')) return Icons.egg_rounded;
    return Icons.inventory_2_rounded;
  }

  Color _getItemColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('gạo')) return Colors.orange.shade700;
    if (n.contains('nước')) return StaffTheme.primaryBlue;
    if (n.contains('mì')) return Colors.red.shade700;
    if (n.contains('áo phao')) return Colors.amber.shade800;
    if (n.contains('thuốc') || n.contains('y tế')) return StaffTheme.successGreen;
    return StaffTheme.primaryBlue;
  }
}

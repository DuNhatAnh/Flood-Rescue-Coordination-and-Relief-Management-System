import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/relief_item.dart';
import '../../services/relief_item_service.dart';
import '../../utils/staff_theme.dart';

class ReliefItemScreen extends StatefulWidget {
  const ReliefItemScreen({Key? key}) : super(key: key);

  @override
  ReliefItemScreenState createState() => ReliefItemScreenState();
}

class ReliefItemScreenState extends State<ReliefItemScreen> {
  final ReliefItemService _service = ReliefItemService();
  List<ReliefItem> _items = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    setState(() => _isLoading = true);
    final items = await _service.getAll();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<String?> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      return await _service.uploadImage(image);
    }
    return null;
  }

  void showAddDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final descController = TextEditingController();
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StaffTheme.cardRadius)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: StaffTheme.primaryBlue),
              const SizedBox(width: 10),
              Text('Thêm hàng cứu trợ', style: StaffTheme.cardTitle),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nhập thông tin vật phẩm mới để lưu vào kho hệ thống.',
                  style: TextStyle(color: StaffTheme.textLight, fontSize: 13),
                ),
                const SizedBox(height: 20),
                
                // Image Picker Preview
                GestureDetector(
                  onTap: () async {
                    final url = await _pickAndUploadImage();
                    if (url != null) {
                      setDialogState(() => uploadedImageUrl = url);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: StaffTheme.background,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: StaffTheme.border),
                    ),
                    child: uploadedImageUrl == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: StaffTheme.textLight, size: 40),
                              SizedBox(height: 8),
                              Text('Thêm hình ảnh', style: TextStyle(color: StaffTheme.textLight)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              'http://localhost:8080$uploadedImageUrl',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên vật phẩm',
                    prefixIcon: const Icon(Icons.label_important_outline, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: 'Đơn vị tính (ví dụ: Thùng, Bộ)',
                    prefixIcon: const Icon(Icons.scale_outlined, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    prefixIcon: const Icon(Icons.description_outlined, color: StaffTheme.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ', style: TextStyle(color: StaffTheme.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StaffTheme.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newItem = ReliefItem(
                    itemName: nameController.text,
                    unit: unitController.text,
                    description: descController.text,
                    imageUrl: uploadedImageUrl,
                  );
                  await _service.create(newItem);
                  await _service.create(newItem);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  loadItems();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm ${newItem.itemName} thành công!'),
                      backgroundColor: StaffTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Lưu vào kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void showEditDialog(ReliefItem item) {
    final nameController = TextEditingController(text: item.itemName);
    final unitController = TextEditingController(text: item.unit);
    final descController = TextEditingController(text: item.description);
    String? uploadedImageUrl = item.imageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF0288D1)),
              SizedBox(width: 10),
              Text('Chỉnh sửa vật phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Picker Preview
                GestureDetector(
                  onTap: () async {
                    final url = await _pickAndUploadImage();
                    if (url != null) {
                      setDialogState(() => uploadedImageUrl = url);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: uploadedImageUrl == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text('Thêm hình ảnh', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              'http://localhost:8080$uploadedImageUrl',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên vật phẩm',
                    prefixIcon: const Icon(Icons.label_important_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: 'Đơn vị tính',
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty && item.id != null) {
                  final updatedItem = ReliefItem(
                    id: item.id,
                    itemName: nameController.text,
                    unit: unitController.text,
                    description: descController.text,
                    imageUrl: uploadedImageUrl,
                  );
                  await _service.update(item.id!, updatedItem);
                  await _service.update(item.id!, updatedItem);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  loadItems();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thành công!'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('Cập nhật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteItem(ReliefItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${item.itemName}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      final success = await _service.delete(item.id!);
      if (success && mounted) {
        loadItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa vật phẩm thành công!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DANH MỤC HÀNG CỨU TRỢ', style: StaffTheme.titleLarge),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: StaffTheme.primaryBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)));
    }
    
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Danh mục hiện đang trống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy nhấn nút "+" để thêm loại hàng mới.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StaffTheme.border),
              boxShadow: StaffTheme.softShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showEditDialog(item),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Compact Thumbnail
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: StaffTheme.primaryBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl != null
                              ? Image.network(
                                  'http://localhost:8080${item.imageUrl}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      Icon(Icons.inventory_2_outlined, color: StaffTheme.primaryBlue.withValues(alpha: 0.5), size: 28),
                                )
                              : Icon(Icons.inventory_2_outlined, color: StaffTheme.primaryBlue.withValues(alpha: 0.5), size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName.toUpperCase(),
                              style: StaffTheme.cardTitle.copyWith(fontSize: 14, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đơn vị: ${item.unit}',
                              style: StaffTheme.cardSubtitle,
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: StaffTheme.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Action Menu
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            showEditDialog(item);
                          } else if (value == 'delete') {
                            deleteItem(item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Sửa')],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [Icon(Icons.delete_outline, size: 20, color: StaffTheme.errorRed), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: StaffTheme.errorRed))],
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert_rounded, color: StaffTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

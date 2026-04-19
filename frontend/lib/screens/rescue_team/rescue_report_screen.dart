import 'dart:io' as dio;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/assignment.dart';
import '../../services/rescue_service.dart';
import '../../utils/staff_theme.dart';
import '../../services/auth_service.dart';

class RescueReportScreen extends StatefulWidget {
  final String assignmentId;
  const RescueReportScreen({Key? key, required this.assignmentId}) : super(key: key);

  @override
  State<RescueReportScreen> createState() => _RescueReportScreenState();
}

class _RescueReportScreenState extends State<RescueReportScreen> {
  final RescueService _rescueService = RescueService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  Assignment? _assignment;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _uploadStatus = "";

  // Form State
  int _rescuedCount = 1;
  String _condition = "Ổn định";
  final TextEditingController _noteController = TextEditingController();
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _actualItems = [];
  List<TextEditingController> _controllers = [];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoading = true);
    try {
      final List<Assignment> tasks = await _rescueService.getMyTasks();
      
      // Tìm nhiệm vụ khớp với assignmentId truyền vào
      final task = tasks.firstWhere(
        (t) => t.id == widget.assignmentId,
        orElse: () => throw Exception("Không tìm thấy nhiệm vụ ID: ${widget.assignmentId}"),
      );

      // HỢP NHẤT: Lấy cả vật phẩm nhiệm vụ VÀ vật phẩm do điều phối viên gán thêm
      // HỢP NHẤT THÔNG MINH: Ưu tiên lấy thông tin có tên và đơn vị đầy đủ
      final Map<String, MissionItem> mergedItems = {};
      
      // Tập hợp tất cả item từ cả 2 danh sách
      final allRawItems = [...task.assignedItems, ...task.missionItems];
      
      for (var item in allRawItems) {
        if (item.itemId.isEmpty) continue;
        
        if (!mergedItems.containsKey(item.itemId)) {
          mergedItems[item.itemId] = item;
        } else {
          // Nếu đã tồn tại, chỉ ghi đè nếu item mới có thông tin đầy đủ hơn (tên không trống)
          final existing = mergedItems[item.itemId]!;
          if (existing.itemName.isEmpty && item.itemName.isNotEmpty) {
            mergedItems[item.itemId] = item;
          }
          // Luôn lấy số lượng lớn nhất hoặc cập nhật nếu cần (tùy nghiệp vụ, ở đây ưu tiên missionItems)
          if (task.missionItems.contains(item)) {
             // Nếu là item từ missionItems, cập nhật số lượng chuẩn
             mergedItems[item.itemId] = MissionItem(
               itemId: item.itemId,
               itemName: item.itemName.isNotEmpty ? item.itemName : existing.itemName,
               unit: item.unit.isNotEmpty ? item.unit : existing.unit,
               quantity: item.quantity
             );
          }
        }
      }
      
      final allReqItems = mergedItems.values.toList();
      
      // Reset controllers
      for (var c in _controllers) {
        c.dispose();
      }
      _controllers = allReqItems.map((item) => TextEditingController(text: '${item.quantity}')).toList();

      setState(() {
        _assignment = task;
        _rescuedCount = task.numberOfPeople ?? 1;
        // Khởi tạo danh sách hàng thực tế dựa trên Items đã xuất kho
        _actualItems = allReqItems.map((item) => {
          'itemId': item.itemId,
          'itemName': item.itemName.isNotEmpty ? item.itemName : 'Vật phẩm',
          'unit': item.unit.isNotEmpty ? item.unit : '-',
          'quantity': item.quantity,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assignment: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin nhiệm vụ: $e'), backgroundColor: StaffTheme.errorRed),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Xác nhận lần cuối trước khi gửi báo cáo quan trọng
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hoàn thành nhiệm vụ?', style: TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.successGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn xác nhận đã hoàn tất cứu hộ và muốn gửi báo cáo kết thúc?'),
            const SizedBox(height: 12),
            Text('Số người cứu được: $_rescuedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: StaffTheme.primaryBlue)),
            Text('Tình trạng: $_condition', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: StaffTheme.successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('XÁC NHẬN GỬI', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
      _uploadStatus = "Đang bắt đầu...";
    });

    try {
      // 1. Upload ảnh
      List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() => _uploadStatus = "Đang tải ảnh ${i + 1}/${_selectedImages.length}...");
        final url = await _rescueService.uploadFile(
          _selectedImages[i], 
          requestId: _assignment?.requestId
        );
        if (url != null) uploadedUrls.add(url);
      }

      // 2. Gửi báo cáo & Hoàn thành
      setState(() => _uploadStatus = "Đang lưu báo cáo & Đóng nhiệm vụ...");
      final success = await _rescueService.submitRescueReport(
        assignmentId: widget.assignmentId,
        rescuedCount: _rescuedCount,
        note: _noteController.text.trim(),
        userId: AuthService.currentUser?.id,
        imageUrls: uploadedUrls,
        actualItems: _actualItems,
        complete: false, // Chuyển sang REPORTED để chờ điều phối viên xác nhận
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Báo cáo đã được gửi! Đang chờ điều phối viên xác nhận.'), backgroundColor: StaffTheme.successGreen),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Gửi báo cáo thất bại");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: StaffTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: const Text('BÁO CÁO KẾT QUẢ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. THỐNG KÊ NẠN NHÂN'),
              const SizedBox(height: 16),
              _buildRescuedCounter(),
              const SizedBox(height: 24),
              _buildConditionSelector(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('2. HÌNH ẢNH HIỆN TRƯỜNG'),
              const SizedBox(height: 16),
              _buildImagePicker(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('3. ĐỐI SOÁT HÀNG CỨU TRỢ'),
              const SizedBox(height: 16),
              _buildReliefAudit(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('4. GHI CHÚ CHI TIẾT'),
              const SizedBox(height: 12),
              _buildNoteField(),
              
              const SizedBox(height: 48),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1));
  }

  Widget _buildRescuedCounter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StaffTheme.softShadow,
      ),
      child: Column(
        children: [
          const Text('Số người cứu được thực tế', style: TextStyle(color: StaffTheme.textLight, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _counterButton(Icons.remove, () => setState(() => _rescuedCount = _rescuedCount > 0 ? _rescuedCount - 1 : 0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('$_rescuedCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
              ),
              _counterButton(Icons.add, () => setState(() => _rescuedCount++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: StaffTheme.primaryBlue, size: 32),
      style: IconButton.styleFrom(backgroundColor: StaffTheme.primaryBlue.withValues(alpha: 0.1)),
    );
  }

  Widget _buildConditionSelector() {
    final conditions = ['Ổn định', 'Cần sơ cứu', 'Chấn thương nặng', 'Nguy kịch'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: conditions.map((c) {
        final isSelected = _condition == c;
        return ChoiceChip(
          label: Text(c),
          selected: isSelected,
          onSelected: (val) => setState(() => _condition = c),
          selectedColor: StaffTheme.primaryBlue,
          labelStyle: TextStyle(color: isSelected ? Colors.white : StaffTheme.textMedium, fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: kIsWeb 
                            ? NetworkImage(_selectedImages[index].path) as ImageProvider
                            : FileImage(dio.File(_selectedImages[index].path)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      top: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('THÊM HÌNH ẢNH MINH CHỨNG'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            side: const BorderSide(color: StaffTheme.primaryBlue, width: 2),
            foregroundColor: StaffTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildReliefAudit() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StaffTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('VẬT PHẨM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: StaffTheme.textLight))),
                Expanded(flex: 1, child: Center(child: Text('ĐÃ XUẤT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: StaffTheme.textLight)))),
                Expanded(flex: 2, child: Center(child: Text('THỰC TẾ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: StaffTheme.textLight)))),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ..._actualItems.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(item['unit'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      // Số lượng đã xuất
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, color: StaffTheme.primaryBlue)),
                        ),
                      ),
                      // Ô nhập thực tế
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _controllers[idx],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: StaffTheme.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: StaffTheme.primaryBlue)),
                            fillColor: StaffTheme.background,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _actualItems[idx]['quantity'] = int.tryParse(val) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < _actualItems.length - 1) 
                  const Divider(height: 16, thickness: 0.5, color: StaffTheme.border),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập ghi chú chi tiết kết quả';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Nhập diễn biến chi tiết, khó khăn hoặc kiến nghị...',
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        if (_isSubmitting) ...[
          Text(_uploadStatus, style: const TextStyle(color: StaffTheme.primaryBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: StaffTheme.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
            ),
            child: const Text('XÁC NHẬN HOÀN THÀNH NHIỆM VỤ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

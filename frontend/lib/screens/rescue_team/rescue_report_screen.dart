import 'package:flutter/material.dart';
import '../../services/rescue_service.dart';
import '../../utils/staff_theme.dart';

class RescueReportScreen extends StatefulWidget {
  const RescueReportScreen({Key? key}) : super(key: key);

  @override
  State<RescueReportScreen> createState() => _RescueReportScreenState();
}

class _RescueReportScreenState extends State<RescueReportScreen> {
  final RescueService _rescueService = RescueService();
  final _formKey = GlobalKey<FormState>();
  
  int _rescuedCount = 1;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    final success = await _rescueService.submitRescueReport(
      assignmentId: 'A1', // Mock ID
      rescuedCount: _rescuedCount,
      note: _noteController.text,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Báo cáo thành công!'), backgroundColor: StaffTheme.successGreen),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi báo cáo thất bại.'), backgroundColor: StaffTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: Text('BÁO CÁO KẾT QUẢ', style: StaffTheme.titleLarge),
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
              Text('KẾT QUẢ CỨU HỘ THỰC TẾ', style: StaffTheme.cardTitle.copyWith(color: StaffTheme.primaryBlue)),
              const SizedBox(height: 24),
              
              const Text('SỐ NGƯỜI ĐÃ CỨU ĐƯỢC', style: TextStyle(color: StaffTheme.textMedium, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: StaffTheme.border),
                  boxShadow: StaffTheme.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _rescuedCount = _rescuedCount > 0 ? _rescuedCount - 1 : 0),
                      icon: const Icon(Icons.remove_circle_outline, color: StaffTheme.primaryBlue, size: 32),
                    ),
                    Text('$_rescuedCount', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: StaffTheme.primaryBlue)),
                    IconButton(
                      onPressed: () => setState(() => _rescuedCount++),
                      icon: const Icon(Icons.add_circle_outline, color: StaffTheme.primaryBlue, size: 32),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('GHI CHÚ / TÌNH HÌNH THỰC TẾ', style: TextStyle(color: StaffTheme.textMedium, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Mô tả tình trạng sức khỏe người dân, khó khăn gặp phải...',
                  hintStyle: const TextStyle(color: StaffTheme.textLight, fontSize: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: StaffTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: StaffTheme.border),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StaffTheme.successGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('HOÀN THÀNH NHIỆM VỤ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

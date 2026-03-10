import 'package:flutter/material.dart';
import '../../services/rescue_service.dart';

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
          const SnackBar(content: Text('Báo cáo thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi báo cáo thất bại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo Cáo Kết Quả')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kết quả cứu hộ thực tế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              
              const Text('Số người đã cứu được:'),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _rescuedCount = _rescuedCount > 0 ? _rescuedCount - 1 : 0),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_rescuedCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => _rescuedCount++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Text('Ghi chú / Tình hình thực tế:'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mô tả tình trạng sức khỏe người dân, khó khăn gặp phải...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('HOÀN THÀNH NHIỆM VỤ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

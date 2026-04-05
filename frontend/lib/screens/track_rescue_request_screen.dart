import 'package:flutter/material.dart';
import '../services/rescue_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';


class TrackRescueRequestScreen extends StatefulWidget {
  const TrackRescueRequestScreen({super.key});

  @override
  State<TrackRescueRequestScreen> createState() =>
      _TrackRescueRequestScreenState();
}

class _TrackRescueRequestScreenState extends State<TrackRescueRequestScreen> {
  final TextEditingController _requestIdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _requestData;
  String? _errorMessage;
  final RescueService _rescueService = RescueService();

  Future<void> _trackRequest() async {
    final requestId = _requestIdController.text.trim();
    if (requestId.isEmpty) {
      setState(() => _errorMessage = "Vui lòng nhập mã yêu cầu");
      return;
    }

    setState(() {
      _isLoading = true;
      _requestData = null;
      _errorMessage = null;
    });

    try {
      final responseData = await _rescueService.trackRescueRequest(requestId);

      if (responseData != null && responseData['success'] == true) {
        setState(() {
          _requestData = responseData['data'];
        });
      } else {
        setState(() => _errorMessage = responseData?['message'] ?? "Không tìm thấy yêu cầu cứu trợ.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Lỗi kết nối máy chủ");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Theo dõi cứu hộ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () async {
              // Xóa session và quay về màn hình chính
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Đăng xuất",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tra cứu yêu cầu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Nhập mã yêu cầu (Request ID) bạn nhận được sau khi gửi thông tin cứu trợ.",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _requestIdController,
                    decoration: InputDecoration(
                      hintText: "VD: RES-XXXX",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _trackRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("TRA CỨU",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            if (_requestData != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final status = _requestData!['status'] ?? 'SUBMITTED';
    final updatedAt = _requestData!['updatedAt'] != null 
        ? DateTime.parse(_requestData!['updatedAt'])
        : DateTime.now();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mã yêu cầu", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(_requestData!['customId'] ?? _requestData!['id'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const Divider(height: 40),
          _buildInfoRow(Icons.location_on_outlined, "Vị trí", _requestData!['addressText'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.description_outlined, "Mô tả", _requestData!['description'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.update, "Cập nhật lúc", DateFormat('HH:mm - dd/MM/yyyy').format(updatedAt)),
          const SizedBox(height: 32),
          const Text("Tiến trình", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildTimeline(status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        text = "Đang chờ xác minh";
        break;
      case 'VERIFIED':
        color = Colors.blue;
        text = "Đã xác minh";
        break;
      case 'ASSIGNED':
        color = Colors.purple;
        text = "Đã phân công";
        break;
      case 'IN_PROGRESS':
        color = Colors.indigo;
        text = "Đang cứu hộ";
        break;
      case 'COMPLETED':
        color = Colors.green;
        text = "Hoàn thành";
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final stages = [
      {'id': 'PENDING', 'label': 'Đã gửi yêu cầu'},
      {'id': 'VERIFIED', 'label': 'Đã xác minh'},
      {'id': 'ASSIGNED', 'label': 'Đã phân công'},
      {'id': 'IN_PROGRESS', 'label': 'Đang thực hiện'},
      {'id': 'COMPLETED', 'label': 'Đã hoàn thành'},
    ];

    int currentIndex = stages.indexWhere((s) => s['id'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: List.generate(stages.length, (index) {
        bool isCompleted = index < currentIndex;
        bool isCurrent = index == currentIndex;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCurrent || isCompleted ? Colors.blue : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted 
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent 
                          ? Container(
                              margin: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            )
                          : null,
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? Colors.blue : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  stages[index]['label']!,
                  style: TextStyle(
                    color: isCurrent || isCompleted ? Colors.black : Colors.grey,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

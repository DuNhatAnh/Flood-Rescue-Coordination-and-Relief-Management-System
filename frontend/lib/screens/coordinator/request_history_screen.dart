import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';

class RequestHistoryScreen extends StatefulWidget {
  final RescueRequest request;

  const RequestHistoryScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  final RescueService _rescueService = RescueService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _rescueService.getRequestHistory(widget.request.id);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử: ${widget.request.citizenName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Chưa có lịch sử xử lý'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final isLast = index == _history.length - 1;
                    return _buildTimelineItem(item, isLast);
                  },
                ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final status = item['status'] ?? '';
    final note = item['note'] ?? '';
    final createdAtStr = item['createdAt'];
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: _getStatusColor(status).withOpacity(0.4), blurRadius: 4)
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getStatusColor(status),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm dd/MM').format(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    note,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.grey;
      case 'VERIFIED': return Colors.blue;
      case 'ASSIGNED': return Colors.orange;
      case 'IN_PROGRESS': return Colors.blueAccent;
      case 'COMPLETED': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Đã tiếp nhận';
      case 'VERIFIED': return 'Đã xác minh';
      case 'ASSIGNED': return 'Đã phân công';
      case 'IN_PROGRESS': return 'Đang thực hiện';
      case 'COMPLETED': return 'Hoàn thành';
      default: return status;
    }
  }
}

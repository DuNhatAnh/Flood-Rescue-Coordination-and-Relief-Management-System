import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _adminService.fetchAllNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'GENERAL';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi thông báo hệ thống'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Nội dung'),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
            value: selectedType,
              items: const [
                DropdownMenuItem(value: 'URGENT', child: Text('Khẩn cấp')),
                DropdownMenuItem(value: 'GENERAL', child: Text('Chung')),
                DropdownMenuItem(value: 'SYSTEM', child: Text('Hệ thống')),
              ],
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: 'Loại thông báo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.sendNotification({
                  'title': titleController.text,
                  'content': contentController.text,
                  'type': selectedType,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadNotifications();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thông báo'),
        actions: [
          IconButton(icon: const Icon(Icons.send), onPressed: _showSendNotificationDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final note = _notifications[index];
                return ListTile(
                  leading: Icon(
                    note['type'] == 'URGENT' ? Icons.warning : Icons.notifications,
                    color: note['type'] == 'URGENT' ? Colors.red : Colors.blue,
                  ),
                  title: Text(note['title'] ?? 'Không tiêu đề'),
                  subtitle: Text(note['content'] ?? ''),
                  trailing: Text(note['createdAt']?.toString().substring(0, 10) ?? ''),
                );
              },
            ),
    );
  }
}

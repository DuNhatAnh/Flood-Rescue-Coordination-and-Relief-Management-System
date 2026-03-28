import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Cập nhật hàm load: Trả về Future để dùng được với RefreshIndicator
  Future<void> _loadNotifications() async {
    setState(() {
      _notificationsFuture = _service.getAllNotifications();
    });
  }

  // Hàm xử lý khi nhấn vào thông báo
  Future<void> _handleMarkAsRead(NotificationModel item) async {
    if (!item.isRead) {
      try {
        await _service.markAsRead(item.id);
        // Sau khi update thành công trên server, tải lại danh sách
        await _loadNotifications(); 
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Không thể cập nhật trạng thái: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo hệ thống'),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Làm mới",
            onPressed: _loadNotifications,
          )
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          // 1. Trạng thái Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          // 2. Trạng thái Lỗi (Quan trọng để fix lỗi "Failed to load")
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 70, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi kết nối: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.replay),
                      label: const Text('Thử lại ngay'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            );
          } 
          
          // 3. Trạng thái Không có dữ liệu
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView( // Dùng ListView để kéo refresh được ngay cả khi trống
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có thông báo nào.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 4. Trạng thái Có dữ liệu thành công
          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                Color priorityColor = item.priority == 'HIGH' ? Colors.red : Colors.blue;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: item.isRead ? 0 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: item.isRead ? Colors.grey[200]! : priorityColor.withOpacity(0.3),
                    ),
                  ),
                  color: item.isRead ? Colors.white : Colors.blue[50]?.withOpacity(0.5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: item.isRead ? Colors.grey[200] : priorityColor.withOpacity(0.1),
                      child: Icon(
                        item.type == 'RESCUE' ? Icons.emergency : Icons.notifications,
                        color: item.isRead ? Colors.grey : priorityColor,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                        color: item.isRead ? Colors.grey[700] : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item.content,
                          style: TextStyle(color: item.isRead ? Colors.grey : Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM HH:mm').format(item.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            if (!item.isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MỚI',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _handleMarkAsRead(item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
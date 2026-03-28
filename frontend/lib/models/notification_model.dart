class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type; 
  final String priority;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
  });

  // Giúp cập nhật trạng thái nhanh chóng ở UI mà không cần fetch lại toàn bộ
  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      // 1. Xử lý ID: Linh hoạt cho cả MongoDB (_id) và SQL (id)
      id: (json['id'] ?? json['_id'] ?? '').toString(), 
      
      // 2. Xử lý String: Đảm bảo không bao giờ bị null
      title: json['title']?.toString() ?? 'Thông báo hệ thống',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      priority: json['priority']?.toString() ?? 'NORMAL',
      
      // 3. Xử lý Boolean: Quan trọng vì một số DB trả về 0/1 thay vì true/false
      isRead: json['isRead'] == true || json['isRead'] == 1, 
      
      // 4. Xử lý DateTime: Sử dụng tryParse để tránh crash khi format ngày sai
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
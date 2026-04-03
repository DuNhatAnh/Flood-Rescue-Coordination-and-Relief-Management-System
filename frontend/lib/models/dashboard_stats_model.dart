import 'dart:convert';

class DashboardStats {
  final int completedTasks;
  final int activeTasks;
  final int pendingTasks;
  final List<LowStockAlert> lowStockAlerts;
  final List<ChartData> topItemsChart;
  final List<ActivityHistory> recentHistory;

  DashboardStats({
    required this.completedTasks,
    required this.activeTasks,
    required this.pendingTasks,
    required this.lowStockAlerts,
    required this.topItemsChart,
    required this.recentHistory,
  });

  // Chuyển đổi từ JSON (Map) sang Object Dart
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      completedTasks: json['completedTasks'] ?? 0,
      activeTasks: json['activeTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      lowStockAlerts: (json['lowStockAlerts'] as List?)
              ?.map((i) => LowStockAlert.fromJson(i))
              .toList() ?? [],
      topItemsChart: (json['topItemsChart'] as List?)
              ?.map((i) => ChartData.fromJson(i))
              .toList() ?? [],
      recentHistory: (json['recentHistory'] as List?)
              ?.map((i) => ActivityHistory.fromJson(i))
              .toList() ?? [],
    );
  }
}

/// 1. Model cho Cảnh báo hàng sắp hết
class LowStockAlert {
  final String itemName;
  final int quantity;
  final int minThreshold;
  final String unit;

  LowStockAlert({
    required this.itemName,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      itemName: json['itemName'] ?? 'Không xác định',
      quantity: json['quantity'] ?? 0,
      minThreshold: json['minThreshold'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

/// 2. Model cho Biểu đồ tiêu thụ vật phẩm (Pie Chart)
class ChartData {
  final String name;
  final double value;
  final String unit;

  ChartData({
    required this.name, 
    required this.value, 
    required this.unit
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      name: json['name'] ?? 'Khác',
      // Đảm bảo ép kiểu về double để fl_chart vẽ được
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}

/// 3. Model cho Lịch sử biến động gần đây (Timeline)
class ActivityHistory {
  final String id;
  final String type;
  final String status;
  final String distributedAt;

  ActivityHistory({
    required this.id,
    required this.type,
    required this.status,
    required this.distributedAt,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      id: json['id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      status: json['status'] ?? 'UNKNOWN',
      distributedAt: json['distributedAt'] ?? '',
    );
  }
}
import 'distribution_item.dart';

class Distribution {
  final String? id;
  final String warehouseId;
  final String requestId;
  final String distributedBy;
  final DateTime distributedAt;
  final String type;
  final String? destinationWarehouseId;
  final String status;
  // Thêm danh sách vật phẩm để fix lỗi ở màn hình Report
  final List<DistributionItem> items; 

  Distribution({
    this.id,
    required this.warehouseId,
    required this.requestId,
    required this.distributedBy,
    required this.distributedAt,
    this.type = 'EXPORT',
    this.destinationWarehouseId,
    this.status = 'COMPLETED',
    this.items = const [], // Mặc định là danh sách rỗng
  });

  factory Distribution.fromJson(Map<String, dynamic> json) {
    return Distribution(
      id: json['id'],
      warehouseId: json['warehouseId'] ?? '',
      requestId: json['requestId'] ?? '',
      distributedBy: json['distributedBy'] ?? '',
      distributedAt: json['distributedAt'] != null 
          ? DateTime.parse(json['distributedAt'])
          : DateTime.now(),
      type: json['type'] ?? 'EXPORT',
      destinationWarehouseId: json['destinationWarehouseId'],
      status: json['status'] ?? 'COMPLETED',
      // Logic xử lý danh sách items từ Backend
      items: json['items'] != null 
          ? (json['items'] as List)
              .map((i) => DistributionItem.fromJson(i))
              .toList()
          : [],
    );
  }
}
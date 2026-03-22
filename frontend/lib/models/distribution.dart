class Distribution {
  final String? id;
  final String warehouseId;
  final String requestId;
  final String distributedBy;
  final DateTime distributedAt;
  final String type;
  final String? destinationWarehouseId;
  final String status;

  Distribution({
    this.id,
    required this.warehouseId,
    required this.requestId,
    required this.distributedBy,
    required this.distributedAt,
    this.type = 'EXPORT',
    this.destinationWarehouseId,
    this.status = 'COMPLETED',
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
    );
  }
}

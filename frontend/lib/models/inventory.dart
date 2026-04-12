class Inventory {
  final String? id; // Changed to nullable
  final String warehouseId;
  final String itemId;
  final String itemName;
  final String unit;
  final int quantity;
  final int? minThreshold; // Thêm ngưỡng tối thiểu
  final String? status; // Thêm trạng thái (NORMAL, LOW_STOCK)
  final String? imageUrl; // Added imageUrl field

  Inventory({
    this.id, // Changed to optional
    required this.warehouseId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    this.minThreshold,
    this.status,
    this.imageUrl, // Added imageUrl to constructor
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'], // Adjusted for nullable id
      warehouseId: json['warehouseId'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      unit: json['unit'] ?? '',
      quantity: json['quantity'] ?? 0,
      minThreshold: json['minThreshold'],
      status: json['status'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Inventory &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          warehouseId == other.warehouseId;

  @override
  int get hashCode => itemId.hashCode ^ warehouseId.hashCode;
}

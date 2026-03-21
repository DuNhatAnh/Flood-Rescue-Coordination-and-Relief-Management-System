class Inventory {
  final String? id; // Changed to nullable
  final String warehouseId;
  final String itemId;
  final String itemName;
  final String unit;
  final int quantity;
  final String? imageUrl; // Added imageUrl field

  Inventory({
    this.id, // Changed to optional
    required this.warehouseId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
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
    };
  }
}

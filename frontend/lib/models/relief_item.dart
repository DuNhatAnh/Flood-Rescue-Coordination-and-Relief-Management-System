class ReliefItem {
  final String? id;
  final String itemName;
  final String unit;
  final String description;
  final String? imageUrl;

  ReliefItem({
    this.id,
    required this.itemName,
    required this.unit,
    required this.description,
    this.imageUrl,
  });

  factory ReliefItem.fromJson(Map<String, dynamic> json) {
    return ReliefItem(
      id: json['id'],
      itemName: json['itemName'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'unit': unit,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}

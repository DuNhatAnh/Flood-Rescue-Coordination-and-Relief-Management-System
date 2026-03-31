class DistributionItem {
  final String itemName;
  final double quantity;
  final String unit;

  DistributionItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  factory DistributionItem.fromJson(Map<String, dynamic> json) {
    return DistributionItem(
      itemName: json['itemName'] ?? 'N/A',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}
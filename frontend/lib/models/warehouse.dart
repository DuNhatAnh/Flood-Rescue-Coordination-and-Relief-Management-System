class Warehouse {
  final String? id;
  final String warehouseName;
  final String location;
  final String? managerId;
  final String status;
  final DateTime? createdAt;

  Warehouse({
    this.id,
    required this.warehouseName,
    required this.location,
    this.managerId,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      warehouseName: json['warehouseName'],
      location: json['location'],
      managerId: json['managerId'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouseName': warehouseName,
      'location': location,
      'managerId': managerId,
      'status': status,
    };
  }
}

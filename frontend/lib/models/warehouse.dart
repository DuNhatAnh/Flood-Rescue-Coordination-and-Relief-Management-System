class Warehouse {
  final String? id;
  final String warehouseName;
  final String location;
  final String? managerId;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  Warehouse({
    this.id,
    required this.warehouseName,
    required this.location,
    this.managerId,
    this.status = 'ACTIVE',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    try {
      final dateStr = json['createdAt']?.toString() ?? json['created_at']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        parsedDate = DateTime.tryParse(dateStr);
      }
    } catch (e) {
      print('Warning: Failed to parse createdAt for warehouse: $e');
    }

    return Warehouse(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      warehouseName: json['warehouseName']?.toString() ?? json['warehouse_name']?.toString() ?? 'Không tên',
      location: json['location']?.toString() ?? json['address']?.toString() ?? 'Chưa cập nhật',
      managerId: json['managerId']?.toString() ?? json['manager_id']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      createdAt: parsedDate,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'warehouseName': warehouseName,
      'location': location,
      'managerId': managerId,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Warehouse && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

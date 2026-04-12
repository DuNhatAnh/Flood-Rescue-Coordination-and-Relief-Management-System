class Vehicle {
  final String id;
  final String vehicleType;
  final String licensePlate;
  final String status; // 'AVAILABLE', 'MAINTENANCE', 'IN_USE'
  final String? currentLocation;
  final String? teamId;
  final String? warehouseId;

  Vehicle({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
    required this.status,
    this.currentLocation,
    this.teamId,
    this.warehouseId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'].toString(),
      vehicleType: json['vehicleType'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      currentLocation: json['currentLocation'],
      teamId: json['teamId']?.toString(),
      warehouseId: json['warehouseId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
      'status': status,
      'currentLocation': currentLocation,
      'teamId': teamId,
      'warehouseId': warehouseId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

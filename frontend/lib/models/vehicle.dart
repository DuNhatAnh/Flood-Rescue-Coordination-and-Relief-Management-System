class Vehicle {
  final String id;
  final String vehicleType;
  final String licensePlate;
  final String status; // 'AVAILABLE', 'MAINTENANCE', 'IN_USE'
  final String? currentLocation;
  final String? teamId;

  Vehicle({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
    required this.status,
    this.currentLocation,
    this.teamId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'].toString(),
      vehicleType: json['vehicleType'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      currentLocation: json['currentLocation'],
      teamId: json['teamId']?.toString(),
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
    };
  }
}

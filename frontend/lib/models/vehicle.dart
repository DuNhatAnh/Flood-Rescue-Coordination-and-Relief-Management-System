class Vehicle {
  final int id;
  final String vehicleType;
  final String licensePlate;
  final String status; // 'AVAILABLE', 'MAINTENANCE', 'IN_USE'
  final String? currentLocation;
  final int? teamId;

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
      id: json['id'],
      vehicleType: json['vehicleType'],
      licensePlate: json['licensePlate'],
      status: json['status'],
      currentLocation: json['currentLocation'],
      teamId: json['teamId'],
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

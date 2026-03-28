
class Assignment {
  final String id;
  final String requestId;
  final String teamId;
  final String teamName;
  final String? vehicleId;
  final DateTime assignedAt;
  final String status; // 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'

  // Fields from RescueRequest (via TaskAssignmentResponse)
  final String? citizenName;
  final String? citizenPhone;
  final String? addressText;
  final String? description;
  final String? urgencyLevel;
  final int? numberOfPeople;
  final double? locationLat;
  final double? locationLng;

  Assignment({
    required this.id,
    required this.requestId,
    required this.teamId,
    required this.teamName,
    this.vehicleId,
    required this.assignedAt,
    this.status = 'IN_PROGRESS',
    this.citizenName,
    this.citizenPhone,
    this.addressText,
    this.description,
    this.urgencyLevel,
    this.numberOfPeople,
    this.locationLat,
    this.locationLng,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      vehicleId: json['vehicleId'],
      assignedAt: json['assignedAt'] != null 
          ? DateTime.parse(json['assignedAt']) 
          : DateTime.now(),
      status: json['status'] ?? 'ASSIGNED',
      citizenName: json['citizenName'],
      citizenPhone: json['citizenPhone'],
      addressText: json['addressText'],
      description: json['description'],
      urgencyLevel: json['urgencyLevel'],
      numberOfPeople: json['numberOfPeople']?.toInt(),
      locationLat: json['locationLat']?.toDouble(),
      locationLng: json['locationLng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'teamId': teamId,
      'teamName': teamName,
      'vehicleId': vehicleId,
      'assignedAt': assignedAt.toIso8601String(),
      'status': status,
      'citizenName': citizenName,
      'citizenPhone': citizenPhone,
      'addressText': addressText,
      'description': description,
      'urgencyLevel': urgencyLevel,
      'numberOfPeople': numberOfPeople,
      'locationLat': locationLat,
      'locationLng': locationLng,
    };
  }
}


class Assignment {
  final String id;
  final String requestId;
  final String teamId;
  final String teamName;
  final String? vehicleId;
  final DateTime assignedAt;
  final String status; // 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'

  Assignment({
    required this.id,
    required this.requestId,
    required this.teamId,
    required this.teamName,
    this.vehicleId,
    required this.assignedAt,
    this.status = 'IN_PROGRESS',
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
      status: json['status'] ?? 'IN_PROGRESS',
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
    };
  }
}

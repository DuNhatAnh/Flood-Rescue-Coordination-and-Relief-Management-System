
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
}

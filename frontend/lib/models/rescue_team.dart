class RescueTeam {
  final String id;
  final String teamName;
  final String status; // 'AVAILABLE', 'BUSY'
  final String leaderId;
  final String? warehouseId;
  double? distance; // Temporary field for sorting

  RescueTeam({
    required this.id,
    required this.teamName,
    required this.status,
    required this.leaderId,
    this.warehouseId,
    this.distance,
  });

  factory RescueTeam.fromJson(Map<String, dynamic> json) {
    return RescueTeam(
      id: json['id'].toString(),
      teamName: json['teamName'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      leaderId: json['leaderId']?.toString() ?? '',
      warehouseId: json['warehouseId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamName': teamName,
      'status': status,
      'leaderId': leaderId,
      'warehouseId': warehouseId,
    };
  }
}

class RescueTeam {
  final String id;
  final String teamName;
  final String status; // 'AVAILABLE', 'BUSY'
  final String leaderId;

  RescueTeam({
    required this.id,
    required this.teamName,
    required this.status,
    required this.leaderId,
  });

  factory RescueTeam.fromJson(Map<String, dynamic> json) {
    return RescueTeam(
      id: json['id'].toString(),
      teamName: json['teamName'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      leaderId: json['leaderId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamName': teamName,
      'status': status,
      'leaderId': leaderId,
    };
  }
}

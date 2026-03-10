class RescueTeam {
  final int id;
  final String teamName;
  final String status; // 'AVAILABLE', 'BUSY'
  final int leaderId;

  RescueTeam({
    required this.id,
    required this.teamName,
    required this.status,
    required this.leaderId,
  });

  factory RescueTeam.fromJson(Map<String, dynamic> json) {
    return RescueTeam(
      id: json['id'],
      teamName: json['teamName'],
      status: json['status'],
      leaderId: json['leaderId'],
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

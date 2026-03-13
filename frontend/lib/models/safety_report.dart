class SafetyReport {
  final String? id;
  final String citizenName;
  final String phone;
  final double? lat;
  final double? lng;
  final String address;
  final String? note;
  final DateTime? reportedAt;

  SafetyReport({
    this.id,
    required this.citizenName,
    required this.phone,
    this.lat,
    this.lng,
    required this.address,
    this.note,
    this.reportedAt,
  });

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    return SafetyReport(
      id: json['id'],
      citizenName: json['citizenName'] ?? '',
      phone: json['phone'] ?? '',
      lat: json['locationLat']?.toDouble(),
      lng: json['locationLng']?.toDouble(),
      address: json['addressText'] ?? '',
      note: json['note'],
      reportedAt: json['reportedAt'] != null 
          ? DateTime.parse(json['reportedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizenName': citizenName,
      'citizenPhone': phone,
      'locationLat': lat,
      'locationLng': lng,
      'addressText': address,
      'note': note,
    };
  }
}

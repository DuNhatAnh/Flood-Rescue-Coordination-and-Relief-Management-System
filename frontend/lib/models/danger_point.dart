
class DangerPoint {
  final String? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double depth;
  final String? createdBy;
  final DateTime? createdAt;

  DangerPoint({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.depth,
    this.createdBy,
    this.createdAt,
  });

  factory DangerPoint.fromJson(Map<String, dynamic> json) {
    return DangerPoint(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'depth': depth,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  // Phân loại mức độ nguy hiểm dựa trên độ sâu
  // Green (< 0.5m), Yellow (0.5m - 2m), Red (> 2m)
  String get riskLevel {
    if (depth < 0.5) return 'LOW';
    if (depth <= 2.0) return 'MEDIUM';
    return 'HIGH';
  }
}


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
  final List<MissionItem> missionItems;
  final List<MissionItem> assignedItems;
  final bool itemsExported;
  final double? locationLat;
  final double? locationLng;

  Assignment({
    required this.id,
    required this.requestId,
    required this.teamId,
    required this.teamName,
    this.vehicleId,
    required this.assignedAt,
    this.status = 'ASSIGNED',
    this.citizenName,
    this.citizenPhone,
    this.addressText,
    this.description,
    this.urgencyLevel,
    this.numberOfPeople,
    this.locationLat,
    this.locationLng,
    this.missionItems = const [],
    this.assignedItems = const [],
    this.itemsExported = false,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    var itemsList = json['missionItems'] as List?;
    List<MissionItem> items = itemsList != null 
        ? itemsList.map((i) => MissionItem.fromJson(i)).toList() 
        : [];

    var assignedList = json['assignedItems'] as List?;
    List<MissionItem> assigned = assignedList != null 
        ? assignedList.map((i) => MissionItem.fromJson(i)).toList() 
        : [];

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
      missionItems: items,
      assignedItems: assigned,
      itemsExported: json['itemsExported'] ?? false,
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
      'missionItems': missionItems.map((i) => i.toJson()).toList(),
      'assignedItems': assignedItems.map((i) => i.toJson()).toList(),
      'itemsExported': itemsExported,
    };
  }
}

class MissionItem {
  final String itemId;
  final String itemName;
  final String unit;
  final int quantity;

  MissionItem({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
  });

  factory MissionItem.fromJson(Map<String, dynamic> json) {
    return MissionItem(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      unit: json['unit'] ?? '',
      quantity: json['quantity']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
    };
  }
}

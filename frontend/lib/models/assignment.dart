

class VehicleSummary {
  final String id;
  final String vehicleType;
  final String licensePlate;

  VehicleSummary({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
  });

  factory VehicleSummary.fromJson(Map<String, dynamic> json) {
    return VehicleSummary(
      id: json['id'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
    };
  }
}

class Assignment {
  final String id;
  final String requestId;
  final String teamId;
  final String teamName;
  final List<String>? vehicleIds;
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
  final String? vehicleType;
  final String? licensePlate;
  final int? rescuedCount;
  final String? reportNote;
  final List<String>? imageUrls;
  final List<MissionItem> actualDistributedItems;
  final List<VehicleSummary> vehicles;

  Assignment({
    required this.id,
    required this.requestId,
    required this.teamId,
    required this.teamName,
    this.vehicleIds,
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
    this.vehicleType,
    this.licensePlate,
    this.rescuedCount,
    this.reportNote,
    this.imageUrls,
    this.actualDistributedItems = const [],
    this.vehicles = const [],
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
      vehicleIds: json['vehicleIds'] != null ? List<String>.from(json['vehicleIds']) : null,
      assignedAt: _parseDateTime(json['assignedAt']),
      status: json['status'] ?? 'ASSIGNED',
      citizenName: json['citizenName'],
      citizenPhone: json['citizenPhone'],
      addressText: json['addressText'],
      description: json['description'],
      urgencyLevel: json['urgencyLevel'],
      numberOfPeople: json['numberOfPeople'] != null ? int.tryParse(json['numberOfPeople'].toString()) ?? 1 : null,
      locationLat: json['locationLat'] != null ? double.tryParse(json['locationLat'].toString()) : null,
      locationLng: json['locationLng'] != null ? double.tryParse(json['locationLng'].toString()) : null,
      missionItems: items,
      assignedItems: assigned,
      itemsExported: json['itemsExported'] ?? false,
      vehicleType: json['vehicleType'],
      licensePlate: json['licensePlate'],
      rescuedCount: json['rescuedCount'],
      reportNote: json['reportNote'],
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      actualDistributedItems: json['actualDistributedItems'] != null 
          ? (json['actualDistributedItems'] as List).map((i) => MissionItem.fromJson(i)).toList() 
          : [],
      vehicles: json['vehicles'] != null 
          ? (json['vehicles'] as List).map((v) => VehicleSummary.fromJson(v)).toList() 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'teamId': teamId,
      'teamName': teamName,
      'vehicleIds': vehicleIds,
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
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is List) {
        if (value.length >= 3) {
          return DateTime(
            value[0] is int ? value[0] : int.parse(value[0].toString()),
            value[1] is int ? value[1] : int.parse(value[1].toString()),
            value[2] is int ? value[2] : int.parse(value[2].toString()),
            value.length > 3 ? (value[3] is int ? value[3] : int.parse(value[3].toString())) : 0,
            value.length > 4 ? (value[4] is int ? value[4] : int.parse(value[4].toString())) : 0,
            value.length > 5 ? (value[5] is int ? value[5] : int.parse(value[5].toString())) : 0,
          );
        }
      }
    } catch (e) {
      print('Error parsing date: $value - $e');
    }
    return DateTime.now();
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

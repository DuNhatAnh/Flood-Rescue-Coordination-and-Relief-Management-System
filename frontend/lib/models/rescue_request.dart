import 'package:flutter/material.dart';

enum UrgencyLevel { level1, level2, level3, level4, level5 }
enum RequestStatus { pending, assigned, completed }

class RescueRequest {
  final String id;
  final String citizenName;
  final String phone;
  final double lat;
  final double lng;
  final String address;
  final String description;
  final UrgencyLevel urgency;
  final RequestStatus status;
  final int numberOfPeople;
  final DateTime createdAt;
  final bool isVerified;

  RescueRequest({
    required this.id,
    required this.citizenName,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.address,
    required this.description,
    this.urgency = UrgencyLevel.level3,
    this.status = RequestStatus.pending,
    required this.numberOfPeople,
    required this.createdAt,
    this.isVerified = false,
  });

  factory RescueRequest.fromJson(Map<String, dynamic> json) {
    return RescueRequest(
      id: json['id'].toString(),
      citizenName: json['citizenName'] ?? '',
      phone: json['citizenPhone'] ?? '',
      lat: (json['locationLat'] as num).toDouble(),
      lng: (json['locationLng'] as num).toDouble(),
      address: json['addressText'] ?? '',
      description: json['description'],
      urgency: _parseUrgency(json['urgencyLevel']),
      status: _parseStatus(json['status']),
      numberOfPeople: json['numberOfPeople'] ?? 1,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
    );
  }

  static UrgencyLevel _parseUrgency(dynamic level) {
    if (level is int) {
      if (level >= 1 && level <= 5) return UrgencyLevel.values[level - 1];
    }
    switch (level?.toString().toUpperCase()) {
      case 'LEVEL1': return UrgencyLevel.level1;
      case 'LEVEL2': return UrgencyLevel.level2;
      case 'LEVEL3': return UrgencyLevel.level3;
      case 'LEVEL4': return UrgencyLevel.level4;
      case 'LEVEL5': return UrgencyLevel.level5;
      case 'HIGH': return UrgencyLevel.level5;
      case 'MEDIUM': return UrgencyLevel.level3;
      case 'LOW': return UrgencyLevel.level1;
      default: return UrgencyLevel.level3;
    }
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ASSIGNED': return RequestStatus.assigned;
      case 'COMPLETED': return RequestStatus.completed;
      default: return RequestStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizenName': citizenName,
      'citizenPhone': phone,
      'locationLat': lat,
      'locationLng': lng,
      'addressText': address,
      'description': description,
      'urgencyLevel': urgency.index + 1,
      'status': status.name.toUpperCase(),
      'numberOfPeople': numberOfPeople,
      'isVerified': isVerified,
    };
  }

  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.level1: return Colors.green;
      case UrgencyLevel.level2: return Colors.lightGreen;
      case UrgencyLevel.level3: return Colors.orange;
      case UrgencyLevel.level4: return Colors.deepOrange;
      case UrgencyLevel.level5: return Colors.red;
    }
  }

  String get urgencyLabel {
    return 'Mức ${urgency.index + 1}';
  }
}

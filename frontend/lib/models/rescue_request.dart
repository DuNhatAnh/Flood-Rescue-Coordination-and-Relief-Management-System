import 'package:flutter/material.dart';

enum UrgencyLevel { low, medium, high }
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

  RescueRequest({
    required this.id,
    required this.citizenName,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.address,
    required this.description,
    this.urgency = UrgencyLevel.medium,
    this.status = RequestStatus.pending,
    required this.numberOfPeople,
    required this.createdAt,
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
    );
  }

  static UrgencyLevel _parseUrgency(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH': return UrgencyLevel.high;
      case 'LOW': return UrgencyLevel.low;
      default: return UrgencyLevel.medium;
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
      'urgencyLevel': urgency.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'numberOfPeople': numberOfPeople,
    };
  }

  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.high:
        return Colors.red;
      case UrgencyLevel.medium:
        return Colors.orange;
      case UrgencyLevel.low:
        return Colors.green;
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.high:
        return 'KHẨN CẤP';
      case UrgencyLevel.medium:
        return 'TRUNG BÌNH';
      case UrgencyLevel.low:
        return 'THẤP';
    }
  }
}

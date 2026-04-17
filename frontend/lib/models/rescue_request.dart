import 'package:flutter/material.dart';

enum UrgencyLevel { low, medium, high }
enum RequestStatus { pending, assigned, completed, rejected }

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
    this.urgency = UrgencyLevel.medium,
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
    switch (level?.toString().toUpperCase()) {
      case 'HIGH': 
      case 'LEVEL5':
      case 'LEVEL4':
        return UrgencyLevel.high;
      case 'LOW':
      case 'LEVEL1':
      case 'LEVEL2':
        return UrgencyLevel.low;
      case 'MEDIUM':
      case 'LEVEL3':
      default:
        return UrgencyLevel.medium;
    }
  }

  static RequestStatus _parseStatus(String? status) {
    if (status == null) return RequestStatus.pending;
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
      case 'VERIFIED':
        return RequestStatus.pending; // Cần điều phối viên xử lý
      case 'COMPLETED': 
        return RequestStatus.completed;
      case 'REJECTED': 
      case 'CANCELLED':
        return RequestStatus.rejected;
      default: 
        // Bao gồm: ASSIGNED, PREPARING, MOVING, ARRIVED, RESCUING, RETURNING, IN_PROGRESS, REPORTED
        return RequestStatus.assigned; // Đã giao cho đội, không hiện trên danh sách cần điều phối nữa
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
      'isVerified': isVerified,
    };
  }

  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.low: return Colors.blue;
      case UrgencyLevel.medium: return Colors.orange;
      case UrgencyLevel.high: return Colors.red;
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.low: return 'Thấp';
      case UrgencyLevel.medium: return 'Trung bình';
      case UrgencyLevel.high: return 'Cao';
    }
  }

  RescueRequest copyWith({
    String? id,
    String? citizenName,
    String? phone,
    double? lat,
    double? lng,
    String? address,
    String? description,
    UrgencyLevel? urgency,
    RequestStatus? status,
    int? numberOfPeople,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return RescueRequest(
      id: id ?? this.id,
      citizenName: citizenName ?? this.citizenName,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

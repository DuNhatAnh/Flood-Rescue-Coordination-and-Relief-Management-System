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
}

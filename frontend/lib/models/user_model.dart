enum UserRole { admin, coordinator, rescueStaff }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.index,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: UserRole.values[json['role']],
    );
  }
}

enum UserRole { admin, coordinator, rescueStaff, user }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? teamId;
  final String? teamName;
  final UserRole role;


  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.teamId,
    this.teamName,
    required this.role,

  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'teamId': teamId,
      'teamName': teamName,
      'role': role.index,

    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      role: UserRole.values[json['role']],

    );
  }
}

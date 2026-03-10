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
}

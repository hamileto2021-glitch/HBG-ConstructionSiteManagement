class AppUser {
  const AppUser({
    required this.id,
    this.companyId,
    this.employeeId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.isActive,
    required this.mustChangePassword,
    this.lastLoginAtUtc,
    required this.roles,
    required this.createdAtUtc,
  });

  final String id;
  final String? companyId;
  final String? employeeId;

  final String email;
  final String firstName;
  final String lastName;
  final String fullName;

  final bool isActive;
  final bool mustChangePassword;

  final DateTime? lastLoginAtUtc;
  final List<String> roles;

  final DateTime createdAtUtc;

  factory AppUser.fromJson(
      Map<String, dynamic> json,
      ) {
    return AppUser(
      id: json['id'] as String,
      companyId: json['companyId'] as String?,
      employeeId: json['employeeId'] as String?,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      fullName: json['fullName'] as String,
      isActive: json['isActive'] as bool,
      mustChangePassword:
      json['mustChangePassword'] as bool,
      lastLoginAtUtc:
      json['lastLoginAtUtc'] == null
          ? null
          : DateTime.parse(
        json['lastLoginAtUtc'] as String,
      ),
      roles: (json['roles'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }
}
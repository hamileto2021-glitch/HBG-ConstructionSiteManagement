class CurrentUser {
  const CurrentUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.roles,
    this.companyId,
    this.employeeId,
  });

  final String userId;
  final String email;
  final String? name;
  final String? companyId;
  final String? employeeId;
  final List<String> roles;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      companyId: json['companyId'] as String?,
      employeeId: json['employeeId'] as String?,
      roles: (json['roles'] as List<dynamic>)
          .map((role) => role.toString())
          .toList(),
    );
  }

  bool hasRole(String role) => roles.contains(role);

  bool hasAnyRole(Iterable<String> requiredRoles) {
    return requiredRoles.any(roles.contains);
  }
}

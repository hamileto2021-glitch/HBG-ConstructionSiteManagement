class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtUtc,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.mustChangePassword,
    required this.roles,
    this.companyId,
    this.employeeId,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAtUtc;
  final String userId;
  final String? companyId;
  final String? employeeId;
  final String email;
  final String fullName;
  final bool mustChangePassword;
  final List<String> roles;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresAtUtc:
          DateTime.parse(json['accessTokenExpiresAtUtc'] as String),
      userId: json['userId'] as String,
      companyId: json['companyId'] as String?,
      employeeId: json['employeeId'] as String?,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      mustChangePassword: json['mustChangePassword'] as bool,
      roles: (json['roles'] as List<dynamic>)
          .map((role) => role.toString())
          .toList(),
    );
  }
}

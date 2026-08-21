import '../../features/auth/data/models/auth_response.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
    this.companyId,
    this.employeeId,
    this.mustChangePassword = false,
  });

  final String userId;
  final String email;
  final String fullName;
  final String? companyId;
  final String? employeeId;
  final Set<String> roles;
  final bool mustChangePassword;

  bool hasRole(String role) {
    return roles.contains(role);
  }

  factory AuthSession.fromAuthResponse(AuthResponse response) {
    return AuthSession(
      userId: response.userId,
      email: response.email,
      fullName: response.fullName,
      companyId: response.companyId,
      employeeId: response.employeeId,
      roles: response.roles.toSet(),
      mustChangePassword: response.mustChangePassword,
    );
  }
}

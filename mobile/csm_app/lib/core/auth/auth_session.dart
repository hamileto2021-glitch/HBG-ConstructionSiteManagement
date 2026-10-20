import '../../features/auth/data/models/auth_response.dart';
import 'package:csm_app/core/auth/role_permissions.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
    required this.role,
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
  final UserRole role;

  final bool mustChangePassword;

  bool hasRole(String roleName) {
    return roles.contains(roleName);
  }

  factory AuthSession.fromAuthResponse(AuthResponse response) {
    final roleSet = response.roles.toSet();

    return AuthSession(
      userId: response.userId,
      email: response.email,
      fullName: response.fullName,
      companyId: response.companyId,
      employeeId: response.employeeId,
      roles: roleSet,
      role: RolePermissions.parse(roleSet.toList()),
      mustChangePassword: response.mustChangePassword,
    );
  }
}
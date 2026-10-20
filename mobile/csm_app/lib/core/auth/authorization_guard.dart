import 'package:flutter/material.dart';

import 'authorization_service.dart';

class AuthorizationGuard extends StatelessWidget {
  const AuthorizationGuard({
    super.key,
    required this.roles,
    required this.canAccess,
    required this.child,
    this.message = 'You are not authorized to access this module.',
  });

  final Set<String> roles;
  final bool Function(AuthorizationService auth) canAccess;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    final auth = AuthorizationService(roles: roles);

    if (canAccess(auth)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
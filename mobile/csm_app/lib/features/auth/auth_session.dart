import 'package:flutter/foundation.dart';

import '../../core/auth/authorization_service.dart';

import 'data/models/current_user.dart';
import 'data/models/login_request.dart';
import 'data/repositories/auth_repository.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthSession extends ChangeNotifier {
  AuthSession({
    AuthRepository? repository,
  }) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initializing;
  CurrentUser? _currentUser;

  AuthStatus get status => _status;
  CurrentUser? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthorizationService get authorization =>
      AuthorizationService(
        roles: _currentUser?.roles.toSet() ?? <String>{},
      );

  Future<void> restoreSession() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    try {
      final response = await _repository.getCurrentUser();

      _currentUser = CurrentUser.fromJson(response);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await _repository.login(
      LoginRequest(
        email: email,
        password: password,
        deviceName: deviceName,
      ),
    );

    final currentUserResponse =
        await _repository.getCurrentUser();

    _currentUser = CurrentUser.fromJson(
      currentUserResponse,
    );

    if (response.userId != _currentUser!.userId) {
      throw StateError(
        'Authenticated user identity does not match login response.',
      );
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}


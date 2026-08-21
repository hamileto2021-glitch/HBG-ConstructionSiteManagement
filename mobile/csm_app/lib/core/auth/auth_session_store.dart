import 'package:flutter/foundation.dart';

import 'auth_session.dart';

class AuthSessionStore extends ChangeNotifier {
  AuthSession? _session;

  AuthSession? get session => _session;

  bool get isAuthenticated => _session != null;

  void setSession(AuthSession session) {
    _session = session;
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }
}

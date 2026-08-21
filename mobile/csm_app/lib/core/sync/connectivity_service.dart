import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> getCurrentConnectivity() {
    return _connectivity.checkConnectivity();
  }

  Future<bool> get isOnline async {
    final results = await getCurrentConnectivity();

    return results.any(
      (result) => result != ConnectivityResult.none,
    );
  }
}

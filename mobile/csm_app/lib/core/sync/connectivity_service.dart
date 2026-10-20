import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('api.nuget.org');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
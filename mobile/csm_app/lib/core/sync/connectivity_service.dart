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

    return true;
  }
}
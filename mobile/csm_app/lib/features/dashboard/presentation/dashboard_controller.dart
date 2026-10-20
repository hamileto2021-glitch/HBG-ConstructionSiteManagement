import 'package:flutter/foundation.dart';

import '../data/models/dashboard_stats.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    DashboardRepository? repository,
  }) : _repository = repository ?? DashboardRepository();

  final DashboardRepository _repository;

  DashboardStats? stats;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      stats = await _repository.getStatistics();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
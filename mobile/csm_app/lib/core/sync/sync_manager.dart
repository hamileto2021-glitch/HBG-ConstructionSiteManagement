import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'sync_engine.dart';
import 'sync_queue_service.dart';
import 'sync_status.dart';

class SyncManager extends ChangeNotifier {
  SyncManager({
    required this._queue,
    required this._engine,
    ConnectivityService? connectivity,
  }) : _connectivity = connectivity ?? ConnectivityService();

  final SyncQueueService _queue;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  SyncStatus _status = const SyncStatus();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncStatus get status => _status;

  bool get isMonitoring =>
      _connectivitySubscription != null;

  Future<SyncStatus> synchronize() async {
    if (_status.isSyncing || _engine.isRunning) {
      return _status;
    }

    final online = await _connectivity.isOnline;

    if (!online) {
      _status = _status.copyWith(
        state: SyncState.failed,
        errorMessage: 'Device is offline.',
      );
      notifyListeners();
      return _status;
    }

    final pendingBeforeSync =
        await _queue.getPending(limit: 1000);

    _status = _status.copyWith(
      state: SyncState.syncing,
      pendingCount: pendingBeforeSync.length,
      clearError: true,
    );
    notifyListeners();

    try {
      final result = await _engine.synchronize();

      final pendingAfterSync =
          await _queue.getPending(limit: 1000);

      final now = DateTime.now().toUtc();

      if (result.failed > 0) {
        _status = _status.copyWith(
          state: SyncState.failed,
          lastSuccessfulSyncUtc: result.processed > 0
              ? now
              : _status.lastSuccessfulSyncUtc,
          pendingCount: pendingAfterSync.length,
          failedCount: result.failed,
          errorMessage:
              'Some offline operations could not be synchronized.',
        );
      } else {
        _status = _status.copyWith(
          state: SyncState.completed,
          lastSuccessfulSyncUtc: now,
          pendingCount: pendingAfterSync.length,
          failedCount: 0,
          clearError: true,
        );
      }
    } catch (error) {
      final pendingAfterFailure =
          await _queue.getPending(limit: 1000);

      _status = _status.copyWith(
        state: SyncState.failed,
        pendingCount: pendingAfterFailure.length,
        failedCount: pendingAfterFailure.length,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();

    return _status;
  }

  Future<void> refreshPendingCount() async {
    final pending =
        await _queue.getPending(limit: 1000);

    _status = _status.copyWith(
      pendingCount: pending.length,
    );

    notifyListeners();
  }

  void startConnectivityMonitoring() {
    if (_connectivitySubscription != null) {
      return;
    }

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      (results) {
        final isOnline = results.any(
          (result) => result != ConnectivityResult.none,
        );

        if (isOnline) {
          unawaited(synchronize());
        }
      },
    );
  }

  Future<void> stopConnectivityMonitoring() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
    super.dispose();
  }
}

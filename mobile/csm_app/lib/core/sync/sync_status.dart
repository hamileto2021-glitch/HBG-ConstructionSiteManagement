enum SyncState {
  idle,
  syncing,
  completed,
  failed,
}

class SyncStatus {
  const SyncStatus({
    this.state = SyncState.idle,
    this.lastSuccessfulSyncUtc,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  final SyncState state;
  final DateTime? lastSuccessfulSyncUtc;
  final int pendingCount;
  final int failedCount;
  final String? errorMessage;

  bool get isSyncing => state == SyncState.syncing;

  bool get hasError => state == SyncState.failed;

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSuccessfulSyncUtc,
    int? pendingCount,
    int? failedCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSuccessfulSyncUtc:
          lastSuccessfulSyncUtc ?? this.lastSuccessfulSyncUtc,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

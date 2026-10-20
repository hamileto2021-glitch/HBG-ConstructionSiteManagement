import '../../../../../core/network/api_client.dart';
import '../models/backup_info.dart';
import '../models/backup_summary.dart';


class BackupRepository {
  BackupRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<BackupInfo>> getBackups() async {
    final json = await _apiClient.get('/backup');

    return (json as List)
        .map((e) => BackupInfo.fromJson(e))
        .toList();
  }

  Future<String> createBackup() async {
    final json = await _apiClient.post('/backup/create');

    return json['fileName'] as String;
  }

  Future<void> restoreBackup() async {
    throw UnimplementedError(
      'Restore upload will be enabled after backend build.',
    );
  }
  Future<BackupSummary> getSummary() async {
    final json = await _apiClient.get('/dashboard/statistics');

    return BackupSummary.fromJson(json);
  }
}
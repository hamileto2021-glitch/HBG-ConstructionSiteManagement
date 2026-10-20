import '../../../../../core/network/api_client.dart';
import '../models/audit_log.dart';

class AuditRepository {
  AuditRepository(this._api);

  final ApiClient _api;

  Future<List<AuditLog>> getLogs({
    String? module,
  }) async {
    var endpoint = '/audit';

    if (module != null && module.isNotEmpty) {
      endpoint += '?module=$module';
    }

    final json = await _api.get(endpoint);

    return (json as List)
        .map((e) => AuditLog.fromJson(e))
        .toList();
  }
}
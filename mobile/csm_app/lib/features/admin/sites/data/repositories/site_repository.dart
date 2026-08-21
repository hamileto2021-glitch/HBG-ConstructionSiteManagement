import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../models/site.dart';

class SiteRepository {
  SiteRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  Future<List<Site>> getAll() async {
    final response = await _apiClient.getList('/Sites');

    return response
        .map((e) => Site.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Site> getById(String siteId) async {
    final response = await _apiClient.get('/Sites/$siteId');

    return Site.fromJson(response);
  }

  Future<Site> create({
    required String siteCode,
    required String name,
    String? description,
    String? address,
    String? city,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
    double? geofenceRadiusMeters,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    String? businessUnitId,
  }) async {
    final companyId = await _storage.getCompanyId();

    if (companyId == null || companyId.isEmpty) {
      throw Exception('Company not found.');
    }

    final response = await _apiClient.post(
      '/Sites',
      body: {
        'companyId': companyId,
        'siteCode': siteCode,
        'name': name,
        'description': description,
        'businessUnitId': businessUnitId,
        'address': address,
        'city': city,
        'region': region,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'geofenceRadiusMeters': geofenceRadiusMeters,
        'plannedStartDate':
        plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
        plannedEndDate?.toIso8601String().split('T').first,
      },
    );

    return Site.fromJson(response);
  }

  Future<Site> update({
    required String siteId,
    required String name,
    String? description,
    String? address,
    String? city,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
    double? geofenceRadiusMeters,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    DateTime? actualStartDate,
    DateTime? actualEndDate,
    String? businessUnitId,
  }) async {
    final response = await _apiClient.put(
      '/Sites/$siteId',
      body: {
        'name': name,
        'description': description,
        'businessUnitId': businessUnitId,
        'address': address,
        'city': city,
        'region': region,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'geofenceRadiusMeters': geofenceRadiusMeters,
        'plannedStartDate':
        plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
        plannedEndDate?.toIso8601String().split('T').first,
        'actualStartDate':
        actualStartDate?.toIso8601String().split('T').first,
        'actualEndDate':
        actualEndDate?.toIso8601String().split('T').first,
      },
    );

    return Site.fromJson(response);
  }

  Future<Site> changeStatus({
    required String siteId,
    required String status,
  }) async {
    final response = await _apiClient.put(
      '/Sites/$siteId/status',
      body: {
        'status': status,
      },
    );

    return Site.fromJson(response);
  }

  Future<void> activate(String siteId) async {
    await _apiClient.put('/Sites/$siteId/activate');
  }

  Future<void> deactivate(String siteId) async {
    await _apiClient.put('/Sites/$siteId/deactivate');
  }
}

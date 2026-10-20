import '../../../../../core/network/api_client.dart';
import '../models/company_settings.dart';
import '../models/company_lookup.dart';


class CompanyRepository {
  CompanyRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CompanySettings> getSettings() async {
    final json = await _apiClient.get('/company/settings');
    return CompanySettings.fromJson(json);
  }

  Future<CompanySettings> updateSettings(
      CompanySettings settings) async {
    final json = await _apiClient.put(
      '/company/settings',
      body: settings.toJson(),
    );

    return CompanySettings.fromJson(json);
  }

  Future<List<CompanyLookup>> getCompanies() async {
    final response = await _apiClient.get('/companies/lookup');

    return (response as List)
        .map((e) => CompanyLookup.fromJson(e))
        .toList();
  }

  Future<CompanySettings> getSettingsById(String id) async {
    final json = await _apiClient.get('/Company/$id/settings');
    return CompanySettings.fromJson(json);
  }


}
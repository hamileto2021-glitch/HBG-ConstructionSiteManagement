import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/auth_session_store.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService(),
        _sessionStore = sessionStore ?? AuthSessionStore();

  final ApiClient _apiClient;
  final SecureStorageService _storage;
  final AuthSessionStore _sessionStore;

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/Auth/login',
      body: request.toJson(),
      authenticated: false,
    );

    final authResponse = AuthResponse.fromJson(response);

    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    // SAVE COMPANY ID
    if (authResponse.companyId != null) {
      await _storage.saveCompanyId(
        authResponse.companyId!,
      );
    }

    _sessionStore.setSession(
      AuthSession.fromAuthResponse(authResponse),
    );

    return authResponse;
  }

  Future<AuthResponse> refresh({
    required String refreshToken,
    String? deviceName,
  }) async {
    final response = await _apiClient.post(
      '/Auth/refresh',
      body: <String, dynamic>{
        'refreshToken': refreshToken,
        'deviceName': deviceName,
      },
      authenticated: false,
    );

    final authResponse = AuthResponse.fromJson(response);

    await _storage.saveTokens(
      accessToken: response['accessToken'],
      refreshToken: response['refreshToken'],
    );

    final companyId = response['companyId'] as String?;

    if (companyId != null && companyId.isNotEmpty) {
      await _storage.saveCompanyId(companyId);
    }

    _sessionStore.setSession(
      AuthSession.fromAuthResponse(authResponse),
    );

    return authResponse;
  }

  Future<Map<String, dynamic>> getCurrentUser() {
    return _apiClient.get('/Auth/me');
  }

  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _apiClient.post(
        '/Auth/logout',
        body: <String, dynamic>{
          'refreshToken': refreshToken,
        },
      );
    }

    await _storage.clearTokens();
    _sessionStore.clearSession();
  }
}

import '../../../../../core/network/api_client.dart';
import '../models/user.dart';


class UserRepository {
  UserRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppUser>> getAll() async {
    final response = await _apiClient.getList('/Users');

    return response
        .map(
          (e) => AppUser.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<AppUser> getById(String userId) async {
    final response = await _apiClient.get('/Users/$userId');
    return AppUser.fromJson(response);
  }

  Future<AppUser> create({
    required String companyId,
    String? employeeId,
    required String email,
    required String firstName,
    required String lastName,
    required String temporaryPassword,
    required List<String> roles,
  }) async {
    final response = await _apiClient.post(
      '/Users',
      body: {
        'companyId': companyId,
        'employeeId': employeeId,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'temporaryPassword': temporaryPassword,
        'roles': roles,
      },
    );

    return AppUser.fromJson(response);
  }

  Future<AppUser> update({
    required String userId,
    required String firstName,
    required String lastName,
    String? employeeId,
  }) async {
    final response = await _apiClient.put(
      '/Users/$userId',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'employeeId': employeeId,
      },
    );

    return AppUser.fromJson(response);
  }

  Future<void> setRoles({
    required String userId,
    required List<String> roles,
  }) async {
    await _apiClient.put(
      '/Users/$userId/roles',
      body: {
        'roles': roles.toSet().toList(), // remove duplicates
      },
    );
  }

  Future<void> activate(String userId) async {
    await _apiClient.put('/Users/$userId/activate');
  }

  Future<void> deactivate(String userId) async {
    await _apiClient.put('/Users/$userId/deactivate');
  }
}
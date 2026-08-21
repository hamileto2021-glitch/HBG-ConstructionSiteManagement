import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    SecureStorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService();

  final http.Client _client;
  final SecureStorageService _storage;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) async {
    return _send(
      'GET',
      path,
      authenticated: authenticated,
    );
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _sendRaw(
      'GET',
      path,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    if (response.body.trim().isEmpty) {
      return <dynamic>[];
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List<dynamic>) {
      return decoded;
    }

    throw const ApiException(
      'The server returned an unexpected collection response format.',
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _send(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _send(
      'PUT',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _send(
      'PATCH',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<void> delete(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _sendRaw(
      'DELETE',
      path,
      authenticated: authenticated,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final response = await _sendRaw(
      method,
      path,
      body: body,
      authenticated: authenticated,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      'The server returned an unexpected response format.',
    );
  }

  Future<http.Response> _sendRaw(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool authenticated,
    bool allowRefresh = true,
  }) async {
    final response = await _sendRequest(
      method,
      path,
      body: body,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );

    if (response.statusCode == 401 &&
        authenticated &&
        allowRefresh) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
        return _sendRaw(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          authenticated: authenticated,
          allowRefresh: false,
        );
      }
    }

    return response;
  }

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final accessToken = await _storage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    final baseUri = Uri.parse(ApiConfig.endpoint(path));

    final uri = queryParameters == null || queryParameters.isEmpty
        ? baseUri
        : baseUri.replace(
            queryParameters: <String, String>{
              ...baseUri.queryParameters,
              ...queryParameters,
            },
          );

    try {
      switch (method) {
        case 'GET':
          return await _client
              .get(uri, headers: headers)
              .timeout(ApiConfig.requestTimeout);

        case 'POST':
          return await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(ApiConfig.requestTimeout);

        case 'PUT':
          return await _client
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(ApiConfig.requestTimeout);

        case 'PATCH':
          return await _client
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(ApiConfig.requestTimeout);

        case 'DELETE':
          return await _client
              .delete(uri, headers: headers)
              .timeout(ApiConfig.requestTimeout);

        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } on ApiException {
      rethrow;
    } on Exception catch (ex) {
      throw ApiException(
        'Unable to connect to the server: $ex',
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      ApiConfig.endpoint('/Auth/refresh'),
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'refreshToken': refreshToken,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        await _storage.clearTokens();
        return false;
      }

      if (response.body.trim().isEmpty) {
        await _storage.clearTokens();
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        await _storage.clearTokens();
        return false;
      }

      final accessToken = decoded['accessToken'];
      final newRefreshToken = decoded['refreshToken'];

      if (accessToken is! String ||
          accessToken.isEmpty ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        await _storage.clearTokens();
        return false;
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } on Exception {
      return false;
    }
  }

  ApiException _buildException(http.Response response) {
    var message = 'Request failed with status ${response.statusCode}.';

    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] is String) {
            message = decoded['message'] as String;
          } else if (decoded['title'] is String) {
            message = decoded['title'] as String;
          } else if (decoded['errors'] is Map<String, dynamic>) {
            final errors = decoded['errors'] as Map<String, dynamic>;

            final buffer = StringBuffer();

            errors.forEach((field, value) {
              if (value is List) {
                for (final item in value) {
                  buffer.writeln('$field: $item');
                }
              } else {
                buffer.writeln('$field: $value');
              }
            });

            message = buffer.toString().trim();
          } else {
            message = response.body;
          }
        } else {
          message = response.body;
        }
      } catch (_) {
        message = response.body;
      }
    }

    return ApiException(
      message,
      statusCode: response.statusCode,
    );
  }
}

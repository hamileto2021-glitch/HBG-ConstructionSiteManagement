import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 5065;
  static const String _configuredBaseUrl =
      String.fromEnvironment('CSM_API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      final configured = Uri.tryParse(_configuredBaseUrl);
      if (configured == null ||
          !configured.hasAuthority ||
          !configured.hasScheme ||
          !configured.path.endsWith('/api') ||
          configured.userInfo.isNotEmpty ||
          configured.hasQuery ||
          configured.hasFragment) {
        throw StateError(
          'CSM_API_BASE_URL must be an absolute API URL ending in /api.',
        );
      }
      if (kReleaseMode && configured.scheme != 'https') {
        throw StateError(
          'Release builds require an HTTPS CSM_API_BASE_URL.',
        );
      }
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    if (kReleaseMode) {
      throw StateError(
        'Set CSM_API_BASE_URL to the production HTTPS API endpoint.',
      );
    }

    return Uri(
      scheme: 'http',
      host: kIsWeb ? '127.0.0.1' : '192.168.1.16',
      port: port,
      path: 'api',
    ).toString();
  }

  static const Duration requestTimeout = Duration(seconds: 30);

  static String endpoint(String path) {
    final normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return '$baseUrl$normalizedPath';
  }

  static String fileUrl(String path) {
    final normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return Uri.parse(baseUrl).replace(
      path: normalizedPath,
      query: null,
      fragment: null,
    ).toString();
  }
}
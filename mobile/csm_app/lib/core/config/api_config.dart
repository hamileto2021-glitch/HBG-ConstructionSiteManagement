import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 5065;

  static String get host {
    if (kIsWeb) {
      return 'localhost';
    }
    return '192.168.1.16';
  }

  static String get baseUrl => Uri(
    scheme: 'http',
    host: host,
    port: port,
    path: 'api',
  ).toString();

  static const Duration requestTimeout = Duration(seconds: 30);

  static String endpoint(String path) {
    final normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return '$baseUrl$normalizedPath';
  }

  static String fileUrl(String path) {
    final normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: normalizedPath,
    ).toString();
  }
}
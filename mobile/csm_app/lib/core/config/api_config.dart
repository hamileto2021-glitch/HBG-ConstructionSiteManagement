class ApiConfig {
  static const String host = '10.0.2.2';
  static const int port = 5065;

  static String get baseUrl =>
      Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: 'api',
      ).toString();

  static const Duration requestTimeout =
      Duration(seconds: 30);

  static String endpoint(String path) {
    final normalizedPath =
        path.startsWith('/') ? path : '/$path';

    return '$baseUrl$normalizedPath';
  }
}

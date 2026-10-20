import 'package:drift/drift.dart';

import 'database_connection_stub.dart'
if (dart.library.io) 'database_connection_mobile.dart'
if (dart.library.js_interop) 'database_connection_web.dart';

QueryExecutor openDatabaseConnection() => createConnection();
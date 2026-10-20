import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter =
  NumberFormat('#,##0.00');

  static String format(num value) {
    return _formatter.format(value);
  }

  static String etb(num value) {
    return 'ETB ${_formatter.format(value)}';
  }
}
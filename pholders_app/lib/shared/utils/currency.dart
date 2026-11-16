import 'package:intl/intl.dart';

/// Formats a monetary value as South African Rand.
///
/// Accepts a `num`, or a `String` (Postgres numeric comes back as a string).
/// Returns an empty string for null / unparseable input so unset prices
/// (e.g. `total_amount` before a pharmacy quote) render blank.
String formatRand(Object? value) {
  final parsed = _asDouble(value);
  if (parsed == null) return '';
  return _formatter.format(parsed);
}

final NumberFormat _formatter = NumberFormat.currency(
  locale: 'en_ZA',
  symbol: 'R',
  decimalDigits: 2,
);

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

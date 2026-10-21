import 'package:dio/dio.dart';

import 'error_code_messages.dart';

/// A normalized error thrown out of the API layer.
///
/// Repositories and middleware should catch [ApiException] rather than
/// `DioException` so callers don't leak the transport type.
class ApiException implements Exception {
  final int? statusCode;

  /// Backend error `code` (e.g. `INVALID_TRANSITION`, `CLAIM_REQUIRED`).
  /// Prefer matching on this over the human-readable [message].
  final String? code;

  final String message;

  const ApiException({
    this.statusCode,
    this.code,
    required this.message,
  });

  /// Extracts an [ApiException] from a [DioException].
  ///
  /// If the http_client interceptor already wrapped the error, returns it
  /// verbatim. Otherwise parses the `{ success, message, code? }` envelope
  /// from the response body.
  factory ApiException.fromDio(DioException e) {
    final wrapped = e.error;
    if (wrapped is ApiException) {
      return ApiException(
        statusCode: wrapped.statusCode,
        code: wrapped.code,
        message: messageForApiCode(wrapped.code, fallback: wrapped.message),
      );
    }

    final status = e.response?.statusCode;
    String? code;
    String message = e.message ?? 'Network error';

    final data = e.response?.data;
    if (data is Map) {
      final c = data['code'];
      if (c is String) code = c;
      final m = data['message'];
      if (m is String && m.isNotEmpty) message = m;
    }

    return ApiException(
      statusCode: status,
      code: code,
      message: messageForApiCode(code, fallback: message),
    );
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $message)';
}

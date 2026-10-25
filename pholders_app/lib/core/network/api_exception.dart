/// A normalized error raised by the API layer.
///
/// Every failure — network, timeout, HTTP error, or malformed payload — is
/// converted into one of these so the UI never has to know about Dio.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.kind = ApiErrorKind.unknown,
  });

  /// A human-readable message safe to show to the user.
  ///
  /// Prefer the backend's own `message` field when present — it is written for
  /// end users (e.g. "Email already registered").
  final String message;

  /// The HTTP status code, when the request reached the server.
  final int? statusCode;

  /// Validation errors returned by the backend (e.g. password strength rules).
  final List<String>? fieldErrors;

  /// Coarse classification used to decide how to react (e.g. log the user out).
  final ApiErrorKind kind;

  /// True when the session is no longer valid and the user must sign in again.
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Coarse categories of API failure.
enum ApiErrorKind {
  /// No connection, DNS failure, or the host is unreachable.
  network,

  /// The request took longer than the configured timeout.
  timeout,

  /// The server responded with a non-2xx status.
  http,

  /// The response body was not the JSON shape we expected.
  badResponse,

  /// Anything else.
  unknown,
}

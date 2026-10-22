import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../shared/constants/app_constants.dart';
import '../auth/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around [Dio] that every repository goes through.
///
/// Responsibilities:
///  * attach the `Authorization: Bearer <jwt>` header to authenticated calls,
///  * unwrap the backend's `{ success, message, data }` envelope,
///  * turn every failure into an [ApiException].
///
/// Repositories therefore deal in plain maps and [ApiException]s, and never
/// import Dio themselves.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConstants.apiBaseUrl
      ..connectTimeout = AppConstants.apiConnectTimeout
      ..receiveTimeout = AppConstants.apiReceiveTimeout
      ..headers = {'Content-Type': 'application/json'}
      // Let non-2xx responses through so we can read the backend's `message`
      // instead of Dio throwing a bare "status 400" error.
      ..validateStatus = (status) => status != null && status < 500;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Called when any request comes back 401/403, so the app can log out.
  ///
  /// Set by the auth middleware at startup.
  void Function()? onUnauthorized;

  /// Sends a GET and returns the decoded `data` object.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: queryParameters));
  }

  /// Sends a POST and returns the decoded `data` object.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(() => _dio.post<dynamic>(path, data: body));
  }

  /// Sends a PATCH and returns the decoded `data` object.
  ///
  /// The order state machine uses PATCH for its transitions.
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(() => _dio.patch<dynamic>(path, data: body));
  }

  /// Sends a PUT and returns the decoded `data` object.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(() => _dio.put<dynamic>(path, data: body));
  }

  /// Sends a PUT carrying a file, as `multipart/form-data`.
  ///
  /// Separate from [put] because the body is [FormData] rather than a JSON
  /// map: Dio writes the boundary and content type itself, and the JSON
  /// encoder would turn the bytes into nonsense. Everything else — the bearer
  /// token, envelope unwrapping, error mapping and the 401 hook — is shared,
  /// because it goes through the same [_send].
  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required FormData formData,
  }) {
    return _send(() => _dio.put<dynamic>(path, data: formData));
  }

  /// Fetches a binary document — a PDF, rather than the usual JSON envelope.
  ///
  /// Separate from [get] because [_send] expects `{ success, message, data }`
  /// and would reject a stream of bytes as an unexpected response. Only the
  /// success path differs: a refusal still arrives as the usual envelope, so
  /// it is decoded here and raised as an [ApiException] like any other call.
  Future<Uint8List> getBytes(String path) async {
    final Response<List<int>> response;
    try {
      response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final status = response.statusCode ?? 0;
    final bytes = response.data;

    if (status >= 200 && status < 300 && bytes != null && bytes.isNotEmpty) {
      return Uint8List.fromList(bytes);
    }

    if (status == 401 || status == 403) onUnauthorized?.call();

    var message = 'The document could not be downloaded.';
    if (bytes != null && bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      } on FormatException {
        // Not JSON either — keep the generic message.
      }
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      kind: ApiErrorKind.http,
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
        kind: ApiErrorKind.badResponse,
      );
    }

    // The backend signals failure with `success: false` and a user-facing
    // `message`, on both 4xx and (occasionally) 200 responses.
    final succeeded = body['success'] == true;
    if (!succeeded) {
      final statusCode = response.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        onUnauthorized?.call();
      }
      throw ApiException(
        message: body['message'] as String? ?? 'The request failed.',
        statusCode: statusCode,
        fieldErrors: (body['errors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        kind: ApiErrorKind.http,
      );
    }

    // Most endpoints nest the payload under `data`; a few return it flat.
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return body;

    // `data` was a list or scalar — hand it back under a predictable key.
    return <String, dynamic>{'data': data};
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message:
              'The server took too long to respond. It may be waking up — '
              'please try again in a moment.',
          kind: ApiErrorKind.timeout,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Could not reach the server. Check your connection.',
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) onUnauthorized?.call();
        final data = e.response?.data;
        return ApiException(
          message: data is Map<String, dynamic>
              ? (data['message'] as String? ?? 'The request failed.')
              : 'The server returned an error (${statusCode ?? 'unknown'}).',
          statusCode: statusCode,
          kind: ApiErrorKind.http,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(
          message: 'Something went wrong: ${e.message ?? 'unknown error'}',
          kind: ApiErrorKind.unknown,
        );
    }
  }
}

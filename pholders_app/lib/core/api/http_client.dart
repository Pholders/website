import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/constants/app_constants.dart';
import 'api_exception.dart';

/// Factory for the shared [Dio] instance used across all repositories.
///
/// Reads `baseUrl` from `--dart-define=API_BASE_URL=...`, defaulting to the
/// backend dev URL. Attaches a Bearer token from [FlutterSecureStorage] on
/// every request and normalizes errors into [ApiException].
class HttpClient {
  static const String defaultBaseUrl = 'http://localhost:3000/api';

  static Dio create({
    required FlutterSecureStorage storage,
    required void Function() onUnauthorized,
  }) {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultBaseUrl,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: AppConstants.tokenStorageKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized();
          }
          final apiEx = ApiException.fromDio(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiEx,
              message: apiEx.message,
            ),
          );
        },
      ),
    );

    return dio;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../domain/entities/admin_profile.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  /// Same key [AuthRepositoryImpl] writes on a successful sign-in.
  static const _tokenKey = AppConstants.tokenStorageKey;

  /// Reads the signed-in admin's account.
  ///
  /// The Dio instance attaches no Authorization header of its own, so the
  /// token is added per request — the same way logout does it.
  @override
  Future<AdminProfile> getProfile() async {
    final token = await secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      throw const ServerFailure('Your session has ended. Please sign in again.');
    }

    try {
      final response = await apiClient.dio.get(
        '/users/admin/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};

      if (data.isEmpty) {
        throw const ServerFailure('Could not read your admin profile.');
      }

      // Raw DB row: snake_case throughout.
      return AdminProfile(
        firstName: data['first_name']?.toString() ?? '',
        lastName: data['last_name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        phone: data['phone']?.toString(),
        status: data['status']?.toString(),
      );
    } on Failure {
      rethrow;
    } on Exception catch (e) {
      // 401 here means the token expired or the session was revoked; the
      // server's own wording is the most useful thing to show.
      throw ServerFailure(
        apiErrorMessage(e, fallback: 'Could not load your admin profile.'),
      );
    }
  }
}

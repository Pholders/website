import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _roleKey = 'auth_role';
  static const _userNameKey = 'auth_user_name';

  /// Joins [nameParts] into a display name, falling back through [fallbacks]
  /// and finally to the local part of [email].
  static String _displayName(
    List<Object?> nameParts, {
    required List<Object?> fallbacks,
    required String email,
  }) {
    String clean(Object? value) => value?.toString().trim() ?? '';

    final name = nameParts.map(clean).where((v) => v.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;

    for (final fallback in fallbacks) {
      final value = clean(fallback);
      if (value.isNotEmpty) return value;
    }
    return email.split('@').first;
  }

  /// Each role revokes its session through its own route; there is no shared
  /// logout. An unrecognised role falls back to the doctor path, which the
  /// server rejects harmlessly — logout is best-effort either way.
  static String _logoutPath(String? role) {
    switch (role) {
      case AppConstants.rolePharmacy:
        return '/users/pharmacy/logout';
      case AppConstants.roleAdmin:
        return '/users/admin/logout';
      default:
        return '/users/doctor/logout';
    }
  }

  /// Signs in against the endpoint for [role].
  ///
  /// `/users/login` is the patient handler — it queries the patients table only
  /// and never sees doctors or pharmacies, so each role has its own route. The
  /// API does not return a role field, so it is taken from the caller.
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String role,
  }) async {
    // Guards a silent misroute: admin has no single-call login, and falling
    // through here would post admin credentials to the doctor endpoint.
    if (role == AppConstants.roleAdmin) {
      throw const ValidationFailure(
        'Admin sign-in is two-step — use adminLogin() then verifyAdminOtp().',
      );
    }

    try {
      final isPharmacy = role == AppConstants.rolePharmacy;
      final response = await apiClient.dio.post(
        isPharmacy ? '/users/pharmacy/login' : '/users/doctor/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw const ServerFailure();
      }

      final body = Map<String, dynamic>.from(response.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};

      // The two roles return completely different shapes. Normalise here so
      // nothing downstream has to know which endpoint was called:
      //
      //            doctor                    pharmacy
      //   token    data.token                data.tokens.accessToken
      //   refresh  none                      data.tokens.refreshToken
      //   profile  flat camelCase on data    data.pharmacy, snake_case
      final String accessToken;
      final String? refreshToken;
      final String userName;

      if (isPharmacy) {
        final tokens = data['tokens'] is Map
            ? Map<String, dynamic>.from(data['tokens'] as Map)
            : <String, dynamic>{};
        final pharmacy = data['pharmacy'] is Map
            ? Map<String, dynamic>.from(data['pharmacy'] as Map)
            : <String, dynamic>{};

        accessToken = tokens['accessToken']?.toString() ?? '';
        refreshToken = tokens['refreshToken']?.toString();
        userName = _displayName(
          [pharmacy['first_name'], pharmacy['last_name']],
          fallbacks: [pharmacy['pharmacy_name'], pharmacy['email']],
          email: email,
        );
      } else {
        accessToken = data['token']?.toString() ?? '';
        refreshToken = null;
        userName = _displayName(
          [data['firstName'], data['lastName']],
          fallbacks: [data['email']],
          email: email,
        );
      }

      if (accessToken.isEmpty) {
        throw const ServerFailure('Login succeeded but no token was returned.');
      }

      final session = AuthSession(
        token: accessToken,
        refreshToken: refreshToken,
        role: role,
        userName: userName,
      );

      await secureStorage.write(key: _tokenKey, value: session.token);
      await secureStorage.write(
          key: _refreshTokenKey, value: session.refreshToken ?? '');
      await secureStorage.write(key: _roleKey, value: session.role);
      await secureStorage.write(key: _userNameKey, value: session.userName);

      return session;
    } on Exception catch (e) {
      // Surface the API's own wording ("Invalid email or password") rather
      // than a raw DioException dump.
      throw ServerFailure(
        apiErrorMessage(e, fallback: 'Could not sign you in. Please try again.'),
      );
    }
  }

  /// Requests an admin login code.
  ///
  /// Unlike doctor and pharmacy, `/users/admin/login` returns no token at all —
  /// only `{data: {email, expiresIn}}` confirming a 6-digit code was emailed.
  /// The session is issued by [verifyAdminOtp].
  ///
  /// No Authorization header is sent: the route is behind `preventAuthenticated`
  /// and answers 403 "Already logged in as …" to any request carrying a valid
  /// token, which would otherwise make a signed-in admin unable to sign in again.
  @override
  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      await apiClient.dio.post(
        '/users/admin/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } on Failure {
      rethrow;
    } on Exception catch (e) {
      // 401 invalid password, 403 unknown/inactive account, 429 rate limit —
      // all carry a usable server message that must reach the user verbatim.
      throw ServerFailure(
        apiErrorMessage(e, fallback: 'Could not sign you in. Please try again.'),
      );
    }
  }

  /// Exchanges an emailed admin code for a session.
  ///
  /// Shape differs from both other roles again:
  ///
  ///            admin
  ///   token    data.token           (flat, like doctor)
  ///   refresh  none                 (admin is never issued a refresh token)
  ///   profile  data.admin, snake_case
  ///
  /// The `admins` table has no role column, so — as with doctor and pharmacy —
  /// the role is supplied here rather than read from the response.
  @override
  Future<AuthSession> verifyAdminOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/users/admin/verify-otp',
        // Field is `otp_code`, not `otp`: the handler reads it straight off the
        // body and answers 400 for anything else.
        data: {
          'email': email,
          'otp_code': otpCode,
        },
      );

      if (response.data == null) {
        throw const ServerFailure('Verification succeeded but returned nothing.');
      }

      final body = Map<String, dynamic>.from(response.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};
      final admin = data['admin'] is Map
          ? Map<String, dynamic>.from(data['admin'] as Map)
          : <String, dynamic>{};

      final accessToken = data['token']?.toString() ?? '';
      if (accessToken.isEmpty) {
        throw const ServerFailure(
            'Verification succeeded but no token was returned.');
      }

      final session = AuthSession(
        token: accessToken,
        refreshToken: null,
        role: AppConstants.roleAdmin,
        userName: _displayName(
          [admin['first_name'], admin['last_name']],
          fallbacks: [admin['email']],
          email: email,
        ),
      );

      await secureStorage.write(key: _tokenKey, value: session.token);
      await secureStorage.write(key: _refreshTokenKey, value: '');
      await secureStorage.write(key: _roleKey, value: session.role);
      await secureStorage.write(key: _userNameKey, value: session.userName);

      return session;
    } on Failure {
      // Already carries the server's wording — re-wrapping would replace it
      // with the generic fallback, since apiErrorMessage only reads
      // DioExceptions.
      rethrow;
    } on Exception catch (e) {
      throw ServerFailure(
        apiErrorMessage(e,
            fallback: 'Could not verify that code. Please try again.'),
      );
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final token = await secureStorage.read(key: _tokenKey);
      final refreshToken = await secureStorage.read(key: _refreshTokenKey);
      final role = await secureStorage.read(key: _roleKey);
      final userName = await secureStorage.read(key: _userNameKey);

      if (token == null || role == null) {
        return null;
      }

      return AuthSession(
          token: token, role: role, userName: userName ?? 'User');
    } on Exception {
      throw const CacheFailure();
    }
  }

  /// Revokes the server session, then clears everything stored locally.
  ///
  /// The network call is best-effort: an expired token, a lost connection or a
  /// role-guard rejection must never strand the user in a logged-in UI, so the
  /// local state is cleared either way.
  @override
  Future<void> logout() async {
    final token = await secureStorage.read(key: _tokenKey);
    final role = await secureStorage.read(key: _roleKey);

    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.dio.post(
          _logoutPath(role),
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on Exception {
        // Nothing to recover: the session either expired or was never valid.
      }
    }

    try {
      await secureStorage.delete(key: _tokenKey);
      // Cleared even though only pharmacies get one — nothing server-side can
      // revoke a refresh token, so deleting it locally is the only guard.
      await secureStorage.delete(key: _refreshTokenKey);
      await secureStorage.delete(key: _roleKey);
      await secureStorage.delete(key: _userNameKey);
    } on Exception {
      throw const CacheFailure();
    }
  }
}

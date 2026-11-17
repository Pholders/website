import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// The result of a successful pharmacy login.
class PharmacySession {
  const PharmacySession({
    required this.token,
    required this.pharmacyName,
    required this.pharmacyId,
  });

  final String token;
  final String pharmacyName;
  final int pharmacyId;
}

/// Pharmacy authentication.
///
/// The three roles do not share a login shape. The doctor returns the JWT at
/// `data.token`; pharmacy and patient both nest it at
/// `data.tokens.accessToken`. This reads the pharmacy shape.
class PharmacyAuthRepository {
  const PharmacyAuthRepository(this._api);

  final ApiClient _api;

  /// Signs a pharmacy in.
  ///
  /// Fails with "Account is inactive" until the account has been activated,
  /// which currently only happens via `verify-otp` using the code emailed at
  /// signup — see the pharmacy activation note in docs/integration-plan.md.
  Future<PharmacySession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/users/pharmacy/login',
      body: {'email': email, 'password': password},
    );

    final tokens = data['tokens'];
    final token = tokens is Map<String, dynamic> ? tokens['accessToken'] : null;
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        message: 'Sign in succeeded but the server returned no token.',
        kind: ApiErrorKind.badResponse,
      );
    }

    final pharmacy = data['pharmacy'];
    final name = pharmacy is Map<String, dynamic>
        ? (pharmacy['pharmacy_name']?.toString() ?? 'Pharmacy')
        : 'Pharmacy';
    final rawId = pharmacy is Map<String, dynamic> ? pharmacy['id'] : null;

    return PharmacySession(
      token: token,
      pharmacyName: name,
      pharmacyId: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
    );
  }

  /// Registers a pharmacy. Logged out only.
  ///
  /// Every field is required, and the password must pass the backend's
  /// strength check (400 otherwise); 409 when the email or the licence
  /// number is already registered. The fields follow
  /// controllers/pharmacyController.js, not the out-of-date Swagger docs.
  ///
  /// The account starts `pending_verification` and the backend emails a
  /// six-digit code, valid for 10 minutes, which [verifyOtp] takes. Returns
  /// that code when the backend hands it back rather than emailing it, as it
  /// does while running in development mode.
  Future<String?> signup({
    required String pharmacyName,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String province,
  }) async {
    final data = await _api.post(
      '/users/pharmacy/signup',
      body: {
        'pharmacy_name': pharmacyName,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'license_number': licenseNumber,
        'city': city,
        'province': province,
      },
    );
    return _devCode(data);
  }

  /// Activates a new pharmacy with the code emailed at signup: the account
  /// becomes `active`, on the Basic tier. The field is `otp_code`, not the
  /// Swagger docs' `otp`.
  Future<void> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    await _api.post(
      '/users/pharmacy/verify-otp',
      body: {'email': email, 'otp_code': otpCode},
    );
  }

  /// Asks for a fresh code. For an account not yet active it is a signup
  /// code, checked by [verifyOtp].
  ///
  /// One per 60 seconds (429 otherwise). The reply is the same whether or
  /// not the account exists. Returns the code when the backend hands it back.
  Future<String?> resendVerification({required String email}) async {
    final data = await _api.post(
      '/users/pharmacy/resend-verification',
      body: {'email': email},
    );
    return _devCode(data);
  }

  /// The code, where a development-mode backend includes it.
  static String? _devCode(Map<String, dynamic> data) {
    for (final key in const ['verification_code', 'otp_code', 'otp']) {
      final code = data[key];
      if (code != null && '$code'.isNotEmpty) return '$code';
    }
    return null;
  }

  /// Revokes the current pharmacy session server-side.
  Future<void> logout() async {
    await _api.post('/users/pharmacy/logout');
  }
}

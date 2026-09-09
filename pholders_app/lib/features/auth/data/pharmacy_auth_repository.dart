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

  /// Revokes the current pharmacy session server-side.
  Future<void> logout() async {
    await _api.post('/users/pharmacy/logout');
  }
}

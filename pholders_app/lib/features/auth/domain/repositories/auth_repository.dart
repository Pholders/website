import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
    required String role,
  });

  /// First leg of admin sign-in: checks the password and emails a 6-digit code.
  ///
  /// Returns no session — `/users/admin/login` issues no token. The token comes
  /// only from [verifyAdminOtp], which is why admin cannot go through [login].
  Future<void> adminLogin({
    required String email,
    required String password,
  });

  /// Second leg of admin sign-in: exchanges the emailed code for a session.
  Future<AuthSession> verifyAdminOtp({
    required String email,
    required String otpCode,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();
}

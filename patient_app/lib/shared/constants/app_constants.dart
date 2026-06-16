/// App-wide string constants and configuration values.
///
/// Keep all magic strings here so they are easy to find and update.
class AppConstants {
  AppConstants._();

  static const String appName = 'PHolders';
  static const String appVersion = '1.0.0';

  // ─── API ────────────────────────────────────────────────────────────────────
  /// Base URL for the REST API. Override via environment config in production.
  static const String apiBaseUrl = 'https://api.pholders.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ─── Auth ───────────────────────────────────────────────────────────────────
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String userRoleStorageKey = 'user_role';

  // ─── Roles ──────────────────────────────────────────────────────────────────
  static const String roleDoctor = 'doctor';
  static const String rolePharmacy = 'pharmacy';
}
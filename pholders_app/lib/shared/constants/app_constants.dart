/// App-wide string constants and configuration values.
///
/// Keep all magic strings here so they are easy to find and update.
class AppConstants {
  AppConstants._();

  static const String appName = 'PHolders';
  static const String appVersion = '1.0.0';

  // ─── API ────────────────────────────────────────────────────────────────────
  /// Base URL for the REST API.
  ///
  /// Override at build time without touching the source:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-system-u8s2.onrender.com/api',
  );

  /// The API is hosted on Render's free tier, which suspends the instance
  /// after inactivity. The first request after a spin-down has been measured
  /// at ~32s, so the timeouts are deliberately generous.
  static const Duration apiConnectTimeout = Duration(seconds: 60);
  static const Duration apiReceiveTimeout = Duration(seconds: 60);

  // ─── Auth ───────────────────────────────────────────────────────────────────
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String userRoleStorageKey = 'user_role';
  static const String userNameStorageKey = 'user_name';

  // ─── Roles ──────────────────────────────────────────────────────────────────
  static const String roleDoctor = 'doctor';
  static const String rolePharmacy = 'pharmacy';
}

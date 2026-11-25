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

  /// Socket.IO defaults to the API host, without its `/api` path.
  ///
  /// Set `WS_URL` at build time when realtime events use a separate host.
  static String get realtimeBaseUrl {
    const configuredUrl = String.fromEnvironment('WS_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    final apiUri = Uri.parse(apiBaseUrl);
    final apiPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    return apiUri.replace(path: apiPath).toString();
  }

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

  /// The email "Remember me" keeps for the login form. Not part of the
  /// session, so signing out leaves it.
  static const String rememberedEmailStorageKey = 'remembered_email';

  /// Prefix for a doctor's "verified today" token, one per email. It lets
  /// this browser skip the two-factor code until midnight, so it is kept on
  /// sign-out; the server ends it at midnight or on a password change.
  static const String trustedDevicePrefix = 'doctor_2fa_trusted_';

  /// When the signed-in user last touched the app, for the 30-minute
  /// inactivity sign-out. Also checked when a closed tab is reopened.
  static const String lastActiveStorageKey = 'last_active_at';

  /// Where an earlier build kept the password. Nothing is written here now;
  /// the key is only deleted, so a password left from then does not linger.
  static const String legacyRememberedPasswordStorageKey =
      'remembered_password';

  // ─── Roles ──────────────────────────────────────────────────────────────────
  static const String roleDoctor = 'doctor';
  static const String rolePharmacy = 'pharmacy';
}

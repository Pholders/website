import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/constants/app_constants.dart';

/// Persists the auth session across page reloads and app restarts.
///
/// Backed by [FlutterSecureStorage], which uses the Keychain / Keystore on
/// mobile and desktop. On Flutter web it falls back to an encrypted entry in
/// `localStorage`, so a reload keeps the user signed in.
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  /// Reads the stored JWT, or null when the user has never signed in.
  Future<String?> readToken() => _read(AppConstants.tokenStorageKey);

  /// Reads the stored role ('doctor' or 'pharmacy').
  Future<String?> readRole() => _read(AppConstants.userRoleStorageKey);

  /// Reads the stored display name.
  Future<String?> readUserName() => _read(AppConstants.userNameStorageKey);

  /// Saves a full session. Called after a successful login.
  Future<void> saveSession({
    required String token,
    required String role,
    required String userName,
  }) async {
    await _write(AppConstants.tokenStorageKey, token);
    await _write(AppConstants.userRoleStorageKey, role);
    await _write(AppConstants.userNameStorageKey, userName);
  }

  /// Removes every stored credential. Called on logout and session expiry.
  Future<void> clear() async {
    for (final key in const [
      AppConstants.tokenStorageKey,
      AppConstants.refreshTokenStorageKey,
      AppConstants.userRoleStorageKey,
      AppConstants.userNameStorageKey,
    ]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Deleting a missing key, or a browser that blocks storage entirely,
        // must not stop the user from logging out.
      }
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // A browser with site data disabled throws here. Treat it as "no
      // session" rather than crashing app startup.
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Storage is unavailable — the session simply won't survive a reload.
    }
  }
}

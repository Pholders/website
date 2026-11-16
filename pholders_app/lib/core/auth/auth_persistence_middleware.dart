import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../../shared/constants/app_constants.dart';
import 'auth_actions.dart';

/// Persists the JWT and role to secure storage whenever the auth state changes.
///
/// Keeps the interceptor in [HttpClient] able to read a fresh token on every
/// request without needing store access.
Middleware<AppState> authPersistenceMiddleware(FlutterSecureStorage storage) {
  return (Store<AppState> store, dynamic action, NextDispatcher next) {
    if (action is LoginSuccessAction) {
      storage.write(key: AppConstants.tokenStorageKey, value: action.token);
      storage.write(key: AppConstants.userRoleStorageKey, value: action.role);
    } else if (action is RestoreSessionAction) {
      storage.write(key: AppConstants.tokenStorageKey, value: action.token);
      storage.write(key: AppConstants.userRoleStorageKey, value: action.role);
    } else if (action is LogoutAction || action is SessionExpiredAction) {
      storage.delete(key: AppConstants.tokenStorageKey);
      storage.delete(key: AppConstants.userRoleStorageKey);
    }
    next(action);
  };
}

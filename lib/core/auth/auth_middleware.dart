import 'dart:async';

import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import 'auth_actions.dart';

/// Simple middleware for authentication used during development/demo.
///
/// - Accepts any login where the password equals 'password' and dispatches
///   [LoginSuccessAction] after a short delay.
/// - Otherwise dispatches [LoginFailureAction].
List<Middleware<AppState>> createAuthMiddleware() {
  void loginMiddleware(
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
  ) {
    if (action is LoginRequestAction) {
      // Let the reducer set isLoading=true
      next(action);

      // Simulate network delay
      Future<void>.delayed(const Duration(seconds: 1)).then((_) {
        if (action.password == 'password') {
          // Determine role heuristically from email for demo purposes
          final role = action.email.contains('pharmacy')
              ? 'pharmacy'
              : 'doctor';
          store.dispatch(LoginSuccessAction(
            token: 'demo-token',
            role: role,
            userName: action.email.split('@').first,
          ));
        } else {
          store.dispatch(const LoginFailureAction(errorMessage: 'Invalid credentials'));
        }
      });
      return;
    }

    next(action);
  }

  return [TypedMiddleware<AppState, LoginRequestAction>(loginMiddleware).call];
}

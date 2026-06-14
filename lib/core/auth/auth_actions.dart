/// Redux Actions for the authentication slice.
///
/// Naming convention: <Verb><Noun>Action
/// All actions are plain Dart objects — no logic inside them.
library;

/// Dispatched when the user submits the login form.
class LoginRequestAction {

  const LoginRequestAction({required this.email, required this.password});
  final String email;
  final String password;
}

/// Dispatched by the middleware when the REST API returns a successful login.
class LoginSuccessAction {

  const LoginSuccessAction({
    required this.token,
    required this.role,
    required this.userName,
  });
  final String token;
  final String role;
  final String userName;
}

/// Dispatched by the middleware when the login REST API call fails.
class LoginFailureAction {

  const LoginFailureAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the user taps logout.
class LogoutAction {
  const LogoutAction();
}

/// Dispatched when a stored token is loaded from secure storage on app start.
class RestoreSessionAction {

  const RestoreSessionAction({
    required this.token,
    required this.role,
    required this.userName,
  });
  final String token;
  final String role;
  final String userName;
}

/// Dispatched when the token refresh REST API call fails (session expired).
class SessionExpiredAction {
  const SessionExpiredAction();
}

/// Redux Actions for the authentication slice.
///
/// Naming convention: <Verb><Noun>Action
/// All actions are plain Dart objects — no logic inside them.

/// Dispatched when the user submits the login form.
class LoginRequestAction {
  final String email;
  final String password;

  const LoginRequestAction({required this.email, required this.password});
}

/// Dispatched by the middleware when the REST API returns a successful login.
class LoginSuccessAction {
  final String token;
  final String role;
  final String userName;

  const LoginSuccessAction({
    required this.token,
    required this.role,
    required this.userName,
  });
}

/// Dispatched by the middleware when the login REST API call fails.
class LoginFailureAction {
  final String errorMessage;

  const LoginFailureAction({required this.errorMessage});
}

/// Dispatched when the user taps logout.
class LogoutAction {
  const LogoutAction();
}

/// Dispatched when a stored token is loaded from secure storage on app start.
class RestoreSessionAction {
  final String token;
  final String role;
  final String userName;

  const RestoreSessionAction({
    required this.token,
    required this.role,
    required this.userName,
  });
}

/// Dispatched when the token refresh REST API call fails (session expired).
class SessionExpiredAction {
  const SessionExpiredAction();
}

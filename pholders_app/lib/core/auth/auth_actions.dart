/// Redux Actions for the authentication slice.
///
/// Naming convention: <Verb><Noun>Action
/// All actions are plain Dart objects — no logic inside them.

/// Dispatched when the user submits the login form.
///
/// [role] selects the endpoint: doctors and pharmacies authenticate through
/// separate routes with different response shapes, and the API returns no role
/// field, so the caller must state which one it is.
class LoginRequestAction {
  final String email;
  final String password;
  final String role;

  const LoginRequestAction({
    required this.email,
    required this.password,
    required this.role,
  });
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

/// Dispatched when an admin submits the login form.
///
/// Separate from [LoginRequestAction] because admin sign-in does not produce a
/// session: the endpoint answers with an emailed code, so this leads to
/// [AdminOtpSentAction] rather than [LoginSuccessAction].
class AdminLoginRequestAction {
  final String email;
  final String password;

  const AdminLoginRequestAction({required this.email, required this.password});
}

/// Dispatched by the middleware once the admin login code has been emailed.
class AdminOtpSentAction {
  final String email;

  const AdminOtpSentAction({required this.email});
}

/// Dispatched when an admin submits the emailed code.
///
/// On success the middleware dispatches [LoginSuccessAction], so everything
/// downstream sees an admin session arriving the same way as any other.
class AdminVerifyOtpAction {
  final String email;
  final String otpCode;

  const AdminVerifyOtpAction({required this.email, required this.otpCode});
}

/// Dispatched when the user submits the signup form.
class SignupRequestAction {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String idPassportNumber;
  final String nationality;
  final String password;
  final String role;

  const SignupRequestAction({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.idPassportNumber,
    required this.nationality,
    required this.password,
    required this.role,
  });
}

/// Dispatched when the user submits the OTP verification form.
class VerifyEmailAction {
  final String email;
  final String otp;
  final String role;

  const VerifyEmailAction({
    required this.email,
    required this.otp,
    required this.role,
  });
}

/// Dispatched by the middleware when email verification succeeds.
class VerifyEmailSuccessAction {
  const VerifyEmailSuccessAction();
}

/// Dispatched by the middleware when email verification fails.
class VerifyEmailFailureAction {
  final String errorMessage;

  const VerifyEmailFailureAction({required this.errorMessage});
}

/// Dispatched by the middleware when signup succeeds.
class SignupSuccessAction {
  final String message;

  const SignupSuccessAction({required this.message});
}

/// Dispatched by the middleware when password reset is requested.
class ForgotPasswordRequestAction {
  final String email;

  const ForgotPasswordRequestAction({required this.email});
}

/// Dispatched by the middleware when password reset succeeds.
class ForgotPasswordSuccessAction {
  final String message;

  const ForgotPasswordSuccessAction({required this.message});
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

import 'auth_actions.dart';
import 'auth_state.dart';

/// Pure reducer function for the [AuthState] slice.
///
/// Takes the current state and an action, returns the next immutable state.
/// No side effects — all async work happens in middleware.
AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginRequestAction ||
      action is SignupRequestAction ||
      action is ForgotPasswordRequestAction ||
      action is VerifyEmailAction ||
      action is AdminLoginRequestAction ||
      action is AdminVerifyOtpAction) {
    return state.copyWith(
        isLoading: true, clearError: true, clearSuccess: true);
  }

  // Step one of admin sign-in succeeded. Deliberately leaves the state
  // unauthenticated — no token exists yet, so the router keeps every admin
  // route closed until the code is verified.
  if (action is AdminOtpSentAction) {
    return state.copyWith(
      isLoading: false,
      clearError: true,
      successMessage: 'We sent a 6-digit code to ${action.email}.',
    );
  }

  if (action is LoginSuccessAction) {
    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
      isLoading: false,
      clearError: true,
    );
  }

  if (action is LoginFailureAction) {
    return state.copyWith(
      isLoading: false,
      errorMessage: action.errorMessage,
    );
  }

  if (action is SignupSuccessAction) {
    return state.copyWith(
      isLoading: false,
      clearError: true,
      successMessage: action.message,
    );
  }

  if (action is VerifyEmailSuccessAction) {
    return state.copyWith(
      isLoading: false,
      clearError: true,
    );
  }

  if (action is VerifyEmailFailureAction) {
    return state.copyWith(
      isLoading: false,
      errorMessage: action.errorMessage,
    );
  }

  if (action is ForgotPasswordSuccessAction) {
    return state.copyWith(
      isLoading: false,
      clearError: true,
      successMessage: action.message,
    );
  }

  if (action is LogoutAction || action is SessionExpiredAction) {
    return AuthState.initial();
  }

  if (action is RestoreSessionAction) {
    if (action.token.isEmpty &&
        action.role.isEmpty &&
        action.userName.isEmpty) {
      return state;
    }

    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
    );
  }

  return state;
}

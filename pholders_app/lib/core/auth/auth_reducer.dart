import 'auth_actions.dart';
import 'auth_state.dart';

/// Pure reducer function for the [AuthState] slice.
///
/// Takes the current state and an action, returns the next immutable state.
/// No side effects — all async work happens in middleware.
AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginRequestAction) {
    return state.copyWith(isLoading: true, clearError: true);
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

  if (action is LogoutAction || action is SessionExpiredAction) {
    return AuthState.initial();
  }

  if (action is RestoreSessionAction) {
    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
    );
  }

  return state;
}

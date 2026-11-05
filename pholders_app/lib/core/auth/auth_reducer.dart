import 'auth_actions.dart';
import 'auth_state.dart';

/// Pure reducer function for the [AuthState] slice.
///
/// Takes the current state and an action, returns the next immutable state.
/// No side effects — all async work happens in middleware.
AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginRequestAction) {
    return state.copyWith(
      isLoading: true,
      isSigningIn: true,
      // A new sign-in takes over from a sign-out still waiting on the server.
      isSigningOut: false,
      clearError: true,
    );
  }

  if (action is DoctorSignupRequestAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is LoginSuccessAction) {
    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
      doctor: action.doctor,
      isLoading: false,
      isSigningIn: false,
      isRestoring: false,
      clearError: true,
    );
  }

  if (action is LoginFailureAction) {
    return state.copyWith(
      isLoading: false,
      isSigningIn: false,
      errorMessage: action.errorMessage,
    );
  }

  if (action is LogoutAction || action is SessionExpiredAction) {
    // isRestoring stays false — startup restore has already happened, and
    // leaving it true would trap the router on the loading screen. The
    // scheme catalogue is kept: it is reference data, holds nothing about
    // the doctor, and refetching it on every login is wasted.
    return AuthState.initial().copyWith(
      isRestoring: false,
      // Only a sign-out the user chose waits on the server; an expired
      // session has nothing left to end.
      isSigningOut: action is LogoutAction,
      medicalAidCatalogue: state.medicalAidCatalogue,
    );
  }

  if (action is LogoutCompletedAction) {
    return state.copyWith(isSigningOut: false);
  }

  if (action is RestoreSessionAction) {
    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
      isRestoring: false,
    );
  }

  if (action is NoStoredSessionAction) {
    return state.copyWith(isRestoring: false);
  }

  if (action is UpdateDoctorProfileAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is UpdateDoctorProfileFailedAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  if (action is UploadDoctorProfileImageAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is UploadDoctorProfileImageFailedAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  if (action is MedicalAidCatalogueLoadedAction) {
    return state.copyWith(medicalAidCatalogue: action.schemes);
  }

  if (action is DoctorProfileLoadedAction) {
    return state.copyWith(
      doctor: action.doctor,
      userName: action.doctor.fullName,
      isLoading: false,
    );
  }

  if (action is DoctorSignupSuccessAction) {
    return state.copyWith(
      isLoading: false,
      signupEmail: action.email,
      clearError: true,
    );
  }

  if (action is ResetSignupAction) {
    return state.copyWith(
        isLoading: false, clearSignup: true, clearError: true);
  }

  if (action is RequestVerificationOtpAction ||
      action is VerifyEmailRequestAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is VerificationOtpSentAction) {
    return state.copyWith(
      isLoading: false,
      signupEmail: action.email,
      devOtpCode: action.devCode,
      clearError: true,
    );
  }

  if (action is VerificationOtpFailedAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  if (action is VerifyEmailSuccessAction) {
    return state.copyWith(
      isLoading: false,
      isEmailVerified: true,
      clearError: true,
    );
  }

  if (action is VerifyEmailFailureAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  if (action is DoctorSignupFailureAction) {
    return state.copyWith(
      isLoading: false,
      errorMessage: action.errorMessage,
    );
  }

  return state;
}

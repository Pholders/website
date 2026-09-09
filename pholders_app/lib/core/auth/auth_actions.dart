/// Redux Actions for the authentication slice.
///
/// Naming convention: <Verb><Noun>Action
/// All actions are plain Dart objects — no logic inside them.
library;

import '../../features/auth/data/models/doctor.dart';

/// Dispatched once at startup so the middleware can restore a stored session.
class AppStartedAction {
  const AppStartedAction();
}

/// Dispatched when the user submits the login form.
class LoginRequestAction {

  const LoginRequestAction({
    required this.email,
    required this.password,
    required this.role,
  });
  final String email;
  final String password;

  /// Which login endpoint to use — 'doctor' or 'pharmacy'.
  final String role;
}

/// Dispatched by the middleware when the REST API returns a successful login.
class LoginSuccessAction {

  const LoginSuccessAction({
    required this.token,
    required this.role,
    required this.userName,
    this.doctor,
  });
  final String token;
  final String role;
  final String userName;

  /// The signed-in doctor's profile. Null for other roles.
  final Doctor? doctor;
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

/// Dispatched when no stored session was found at startup, so the router can
/// stop waiting and let the user through to the public pages.
class NoStoredSessionAction {
  const NoStoredSessionAction();
}

/// Dispatched when the token refresh REST API call fails (session expired).
class SessionExpiredAction {
  const SessionExpiredAction();
}

/// Dispatched when a fresh doctor profile arrives from `GET /doctor/profile`.
class DoctorProfileLoadedAction {

  const DoctorProfileLoadedAction({required this.doctor});
  final Doctor doctor;
}

/// Dispatched when the doctor registration form is submitted.
class DoctorSignupRequestAction {

  const DoctorSignupRequestAction({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.hpcsaNumber,
    required this.specialization,
    required this.experience,
    required this.clinicName,
    required this.city,
    required this.province,
    required this.clinicAddress,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String hpcsaNumber;
  final String specialization;
  final int experience;
  final String clinicName;
  final String city;
  final String province;
  final String clinicAddress;
}

/// Dispatched when registration succeeds. The account is created and active;
/// the user still needs to sign in.
class DoctorSignupSuccessAction {

  const DoctorSignupSuccessAction({required this.email});
  final String email;
}

/// Dispatched when registration fails.
class DoctorSignupFailureAction {

  const DoctorSignupFailureAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the registration form is opened, so a previous run's
/// result does not immediately bounce the user to the verification screen.
class ResetSignupAction {
  const ResetSignupAction();
}

/// Dispatched to ask the backend to email a fresh activation code.
class RequestVerificationOtpAction {

  const RequestVerificationOtpAction({required this.email});
  final String email;
}

/// Dispatched once the activation code has been requested.
class VerificationOtpSentAction {

  const VerificationOtpSentAction({required this.email, this.devCode});
  final String email;

  /// The code itself, when the backend hands it back instead of emailing it.
  /// Only happens while the server runs with NODE_ENV=development.
  final String? devCode;
}

/// Dispatched when requesting an activation code fails.
class VerificationOtpFailedAction {

  const VerificationOtpFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the user submits the six-digit activation code.
class VerifyEmailRequestAction {

  const VerifyEmailRequestAction({required this.email, required this.otpCode});
  final String email;
  final String otpCode;
}

/// Dispatched once the account has been activated.
class VerifyEmailSuccessAction {
  const VerifyEmailSuccessAction();
}

/// Dispatched when the activation code is rejected.
class VerifyEmailFailureAction {

  const VerifyEmailFailureAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the doctor saves changes to their profile.
///
/// Only the fields being changed are carried; the repository omits nulls so a
/// partial edit does not blank anything else.
class UpdateDoctorProfileAction {
  const UpdateDoctorProfileAction({
    this.firstName,
    this.lastName,
    this.phone,
    this.specialization,
    this.experience,
    this.clinicName,
    this.clinicAddress,
    this.city,
    this.province,
    this.zipCode,
  });

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? specialization;
  final int? experience;
  final String? clinicName;
  final String? clinicAddress;
  final String? city;
  final String? province;
  final String? zipCode;
}

/// Dispatched when a profile save fails.
class UpdateDoctorProfileFailedAction {

  const UpdateDoctorProfileFailedAction({required this.errorMessage});
  final String errorMessage;
}

import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../../features/auth/data/doctor_auth_repository.dart';
import '../../features/auth/data/pharmacy_auth_repository.dart';
import '../../shared/constants/app_constants.dart';
import '../network/api_exception.dart';
import 'auth_actions.dart';
import 'token_storage.dart';

/// Redux middleware that performs all authentication side effects.
///
/// Reducers stay pure; every network call and every write to secure storage
/// happens here.
/// How long a doctor can leave the app untouched before being signed out
/// (agreed with the team on 2026-11-24).
const Duration inactivityLimit = Duration(minutes: 30);

List<Middleware<AppState>> createAuthMiddleware({
  required DoctorAuthRepository doctorAuth,
  required PharmacyAuthRepository pharmacyAuth,
  required TokenStorage tokenStorage,
}) {
  Future<void> handleAppStarted(Store<AppState> store) async {
    final token = await tokenStorage.readToken();
    final role = await tokenStorage.readRole();

    if (token == null || token.isEmpty || role == null) {
      store.dispatch(const NoStoredSessionAction());
      return;
    }

    final userName = await tokenStorage.readUserName() ?? '';
    store.dispatch(
      RestoreSessionAction(token: token, role: role, userName: userName),
    );

    // A doctor's tab reopened after more than 30 minutes away is signed out,
    // as it would have been had it stayed open. No record (an older build)
    // means no evidence of idling, so the session is kept.
    if (role == AppConstants.roleDoctor) {
      final lastActive = await tokenStorage.readLastActive();
      if (lastActive != null &&
          DateTime.now().difference(lastActive) > inactivityLimit) {
        store.dispatch(const InactivityLogoutAction());
        return;
      }
    }

    // Refresh the profile in the background. This also validates the stored
    // token: if it has expired the API returns 401 and we sign the user out.
    if (role == AppConstants.roleDoctor) {
      try {
        final doctor = await doctorAuth.fetchProfile();
        store.dispatch(DoctorProfileLoadedAction(doctor: doctor));
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await tokenStorage.clear();
          store.dispatch(const SessionExpiredAction());
        }
        // Any other failure (offline, Render cold start) leaves the restored
        // session in place — the user keeps working with cached details.
      }
    }
  }

  /// True when a login endpoint answered but would not sign these credentials
  /// in — wrong password, or no such account there. A network or server
  /// failure is not a reason to try the other endpoint.
  bool rejectsCredentials(ApiException e) =>
      const {400, 401, 403, 404}.contains(e.statusCode);

  /// Everything after the server has accepted a doctor: keep the session,
  /// report success, and load the full profile.
  Future<void> completeDoctorSignIn(
    Store<AppState> store,
    DoctorSession session,
  ) async {
    final trusted = session.trustedDeviceToken;
    if (trusted != null) {
      await tokenStorage.saveTrustedDeviceToken(session.doctor.email, trusted);
    }
    await tokenStorage.saveLastActive(DateTime.now());

    // Store the token before anything else — the ApiClient interceptor reads
    // it from storage, so the profile call below depends on it being there.
    await tokenStorage.saveSession(
      token: session.token,
      role: AppConstants.roleDoctor,
      userName: session.doctor.fullName,
    );

    store.dispatch(LoginSuccessAction(
      token: session.token,
      role: AppConstants.roleDoctor,
      userName: session.doctor.fullName,
      doctor: session.doctor,
    ));

    // The login payload is only a summary; fetch the full profile so the
    // settings screens have clinic details, fees and so on.
    try {
      final doctor = await doctorAuth.fetchProfile();
      store.dispatch(DoctorProfileLoadedAction(doctor: doctor));
    } on ApiException {
      // Non-fatal: the user is signed in with the summary from login.
    }
  }

  /// Signs in as a doctor. Throws [ApiException] when the login call fails.
  ///
  /// With two-factor sign-in on, this throws [TwoFactorRequired] unless the
  /// browser entered a code today; [handleLogin] then asks for the code.
  Future<void> loginDoctor(
    Store<AppState> store,
    LoginRequestAction action,
  ) async {
    final session = await doctorAuth.login(
      email: action.email,
      password: action.password,
      trustedDeviceToken:
          await tokenStorage.readTrustedDeviceToken(action.email),
    );
    await completeDoctorSignIn(store, session);
  }

  /// Signs in as a pharmacy. Throws [ApiException] when the login call fails.
  Future<void> loginPharmacy(
    Store<AppState> store,
    LoginRequestAction action,
  ) async {
    final session = await pharmacyAuth.login(
      email: action.email,
      password: action.password,
    );
    await tokenStorage.saveSession(
      token: session.token,
      role: AppConstants.rolePharmacy,
      userName: session.pharmacyName,
    );
    store.dispatch(LoginSuccessAction(
      token: session.token,
      role: AppConstants.rolePharmacy,
      userName: session.pharmacyName,
    ));
  }

  Future<void> handleLogin(
    Store<AppState> store,
    LoginRequestAction action,
  ) async {
    try {
      switch (action.role) {
        case AppConstants.roleDoctor:
          await loginDoctor(store, action);
        case AppConstants.rolePharmacy:
          await loginPharmacy(store, action);
        default:
          // The login form does not ask which kind of account this is, so
          // try the doctor endpoint and fall back to the pharmacy one.
          try {
            await loginDoctor(store, action);
          } on ApiException catch (doctorError) {
            if (!rejectsCredentials(doctorError)) rethrow;
            try {
              await loginPharmacy(store, action);
            } on ApiException catch (pharmacyError) {
              // Neither knows these credentials: report the doctor endpoint's
              // message. Any other pharmacy failure (offline, server error)
              // is the more useful one to show.
              throw rejectsCredentials(pharmacyError)
                  ? doctorError
                  : pharmacyError;
            }
          }
      }
      // Only an email that signed in is worth remembering.
      switch (action.rememberMe) {
        case true:
          await tokenStorage.rememberEmail(action.email);
        case false:
          await tokenStorage.rememberEmail(null);
        case null:
          break;
      }
    } on TwoFactorRequired catch (required) {
      // The password was right; the form now asks for the emailed code.
      store.dispatch(LoginCodeRequiredAction(email: required.email));
    } on ApiException catch (e) {
      if (action.rememberMe == false) {
        await tokenStorage.rememberEmail(null);
      }
      store.dispatch(LoginFailureAction(errorMessage: e.message));
    }
  }

  /// Finishes a two-factor sign-in with the emailed code. A wrong code keeps
  /// the form on the code step, with the reason shown.
  Future<void> handleVerifyLoginCode(
    Store<AppState> store,
    VerifyLoginCodeAction action,
  ) async {
    try {
      final session = await doctorAuth.verifyLoginCode(
        email: action.email,
        code: action.code,
      );
      await completeDoctorSignIn(store, session);
      switch (action.rememberMe) {
        case true:
          await tokenStorage.rememberEmail(action.email);
        case false:
          await tokenStorage.rememberEmail(null);
        case null:
          break;
      }
    } on ApiException catch (e) {
      store.dispatch(LoginFailureAction(errorMessage: e.message));
    }
  }

  Future<void> handleSignup(
    Store<AppState> store,
    DoctorSignupRequestAction action,
  ) async {
    try {
      final doctor = await doctorAuth.signup(
        firstName: action.firstName,
        lastName: action.lastName,
        email: action.email,
        phone: action.phone,
        password: action.password,
        hpcsaNumber: action.hpcsaNumber,
        specialization: action.specialization,
        experience: action.experience,
        clinicName: action.clinicName,
        city: action.city,
        province: action.province,
        clinicAddress: action.clinicAddress,
      );
      store.dispatch(DoctorSignupSuccessAction(email: doctor.email));

      // Signup does not send an activation code — the backend creates the
      // account already `active` and simply says "please log in". So ask for
      // one explicitly, otherwise the verification screen has nothing to
      // verify. A failure here is not fatal: the account still works.
      try {
        final devCode =
            await doctorAuth.resendVerification(email: doctor.email);
        store.dispatch(VerificationOtpSentAction(
          email: doctor.email,
          devCode: devCode,
        ));
      } on ApiException {
        store.dispatch(VerificationOtpSentAction(email: doctor.email));
      }
    } on ApiException catch (e) {
      final message = DoctorAuthRepository.isGeocodingFailure(e)
          ? 'We could not locate that clinic address. Try the city or suburb '
              'name on its own, for example "Johannesburg".'
          : [e.message, ...?e.fieldErrors].join('\n');
      store.dispatch(DoctorSignupFailureAction(errorMessage: message));
    }
  }

  Future<void> handlePharmacySignup(
    Store<AppState> store,
    PharmacySignupRequestAction action,
  ) async {
    try {
      // Unlike the doctor's, this signup emails its own code.
      final devCode = await pharmacyAuth.signup(
        pharmacyName: action.pharmacyName,
        firstName: action.firstName,
        lastName: action.lastName,
        email: action.email,
        phone: action.phone,
        password: action.password,
        licenseNumber: action.licenseNumber,
        city: action.city,
        province: action.province,
      );
      store.dispatch(
          PharmacySignupSuccessAction(email: action.email, devCode: devCode));
    } on ApiException catch (e) {
      store.dispatch(DoctorSignupFailureAction(
        errorMessage: [e.message, ...?e.fieldErrors].join('\n'),
      ));
    }
  }

  Future<void> requestOtp(
    Store<AppState> store,
    RequestVerificationOtpAction action,
  ) async {
    try {
      // A pharmacy and a doctor resend their codes at different endpoints.
      final devCode = store.state.authState.isPharmacySignup
          ? await pharmacyAuth.resendVerification(email: action.email)
          : await doctorAuth.resendVerification(email: action.email);
      store.dispatch(
        VerificationOtpSentAction(email: action.email, devCode: devCode),
      );
    } on ApiException catch (e) {
      store.dispatch(VerificationOtpFailedAction(errorMessage: e.message));
    }
  }

  Future<void> verifyEmail(
    Store<AppState> store,
    VerifyEmailRequestAction action,
  ) async {
    try {
      if (store.state.authState.isPharmacySignup) {
        await pharmacyAuth.verifyOtp(
          email: action.email,
          otpCode: action.otpCode,
        );
      } else {
        await doctorAuth.verifyEmail(
          email: action.email,
          otpCode: action.otpCode,
        );
      }
      store.dispatch(const VerifyEmailSuccessAction());
    } on ApiException catch (e) {
      store.dispatch(VerifyEmailFailureAction(errorMessage: e.message));
    }
  }

  Future<void> loadMedicalAidCatalogue(Store<AppState> store) async {
    try {
      final schemes = await doctorAuth.fetchMedicalAidCatalogue();
      store.dispatch(MedicalAidCatalogueLoadedAction(schemes: schemes));
    } on ApiException {
      // A backend without the catalogue endpoint leaves the picker empty
      // rather than breaking the settings screen around it.
    }
  }

  Future<void> updateProfile(
    Store<AppState> store,
    UpdateDoctorProfileAction action,
  ) async {
    try {
      final doctor = await doctorAuth.updateProfile(
        firstName: action.firstName,
        lastName: action.lastName,
        phone: action.phone,
        specialization: action.specialization,
        experience: action.experience,
        clinicName: action.clinicName,
        clinicAddress: action.clinicAddress,
        city: action.city,
        province: action.province,
        zipCode: action.zipCode,
        qualification: action.qualification,
        bio: action.bio,
        consultationFee: action.consultationFee,
        medicalAidIds: action.medicalAidIds,
        availability: action.availability,
        notificationPreferences: action.notificationPreferences,
      );
      store.dispatch(DoctorProfileLoadedAction(doctor: doctor));
      // Keep the stored display name in step with the change.
      final token = store.state.authState.token;
      if (token != null) {
        await tokenStorage.saveSession(
          token: token,
          role: AppConstants.roleDoctor,
          userName: doctor.fullName,
        );
      }
    } on ApiException catch (e) {
      store.dispatch(UpdateDoctorProfileFailedAction(errorMessage: e.message));
    }
  }

  Future<void> uploadProfileImage(
    Store<AppState> store,
    UploadDoctorProfileImageAction action,
  ) async {
    try {
      await doctorAuth.uploadProfileImage(
        bytes: action.bytes,
        filename: action.filename,
        contentType: action.contentType,
      );
      // Re-read the profile rather than patching the URL in: the server owns
      // the stored value, and this keeps one path for how a Doctor reaches
      // the store.
      final doctor = await doctorAuth.fetchProfile();
      store.dispatch(DoctorProfileLoadedAction(doctor: doctor));
    } on ApiException catch (e) {
      store.dispatch(
          UploadDoctorProfileImageFailedAction(errorMessage: e.message));
    }
  }

  /// Ends the session on the server, then forgets it here.
  ///
  /// [role] is the role from before the reducer cleared the state. Reading it
  /// here was always null, and the token was deleted before the call that
  /// needed it, so the server session was never actually ended: the token
  /// stayed valid for its full 24 hours. The UI is already signed out by the
  /// reducer; the splash covers this call, capped so a cold-started server
  /// cannot hold it up.
  Future<void> handleLogout(Store<AppState> store, String? role) async {
    try {
      if (role == AppConstants.roleDoctor) {
        await doctorAuth.logout().timeout(const Duration(seconds: 6));
      } else if (role == AppConstants.rolePharmacy) {
        await pharmacyAuth.logout().timeout(const Duration(seconds: 6));
      }
    } catch (_) {
      // Offline, timed out or already revoked: the local session still goes.
    } finally {
      await tokenStorage.clear();
      store.dispatch(const LogoutCompletedAction());
    }
  }

  void authMiddleware(
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
  ) {
    // Signing out clears the role in the reducer, so note it first.
    final roleBefore = store.state.authState.role;

    // Let the reducer update state first (e.g. set isLoading), then run the
    // side effect.
    next(action);

    if (action is AppStartedAction) {
      handleAppStarted(store);
    } else if (action is LoginRequestAction) {
      handleLogin(store, action);
    } else if (action is DoctorSignupRequestAction) {
      handleSignup(store, action);
    } else if (action is PharmacySignupRequestAction) {
      handlePharmacySignup(store, action);
    } else if (action is LoadMedicalAidCatalogueAction) {
      loadMedicalAidCatalogue(store);
    } else if (action is UpdateDoctorProfileAction) {
      updateProfile(store, action);
    } else if (action is UploadDoctorProfileImageAction) {
      uploadProfileImage(store, action);
    } else if (action is RequestVerificationOtpAction) {
      requestOtp(store, action);
    } else if (action is VerifyEmailRequestAction) {
      verifyEmail(store, action);
    } else if (action is VerifyLoginCodeAction) {
      handleVerifyLoginCode(store, action);
    } else if (action is LogoutAction) {
      handleLogout(store, roleBefore);
    } else if (action is SessionExpiredAction) {
      tokenStorage.clear();
    }
  }

  return [authMiddleware];
}

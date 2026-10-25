import 'package:redux/redux.dart';

import '../../core/auth/auth_actions.dart';
import '../../core/di/service_locator.dart';
import '../../core/error/failures.dart';
import '../../core/network/legacy_api_client.dart';
import '../../core/usecases/usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../app_state.dart';

class AuthMiddleware {
  AuthMiddleware() {
    loginUseCase = LoginUseCase(sl());
    restoreSessionUseCase = RestoreSessionUseCase(sl());
    adminLoginUseCase = AdminLoginUseCase(sl());
    verifyAdminOtpUseCase = VerifyAdminOtpUseCase(sl());
  }

  late final LoginUseCase loginUseCase;
  late final RestoreSessionUseCase restoreSessionUseCase;
  late final AdminLoginUseCase adminLoginUseCase;
  late final VerifyAdminOtpUseCase verifyAdminOtpUseCase;

  List<Middleware<AppState>> get middleware => [
        TypedMiddleware<AppState, LoginRequestAction>(_handleLogin).call,
        TypedMiddleware<AppState, RestoreSessionAction>(_handleRestoreSession)
            .call,
        TypedMiddleware<AppState, LogoutAction>(_handleLogout).call,
        TypedMiddleware<AppState, VerifyEmailAction>(_handleVerifyEmail).call,
        TypedMiddleware<AppState, ForgotPasswordRequestAction>(
          _handleForgotPassword,
        ).call,
        TypedMiddleware<AppState, AdminLoginRequestAction>(_handleAdminLogin)
            .call,
        TypedMiddleware<AppState, AdminVerifyOtpAction>(_handleAdminVerifyOtp)
            .call,
      ];

  /// Step one of admin sign-in: password check, then an emailed code.
  ///
  /// Failures reuse [LoginFailureAction] so the shared error surface renders
  /// the server's own wording without the admin pages knowing about Dio.
  Future<void> _handleAdminLogin(
    Store<AppState> store,
    AdminLoginRequestAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      await adminLoginUseCase.call(
        AdminLoginParams(email: action.email, password: action.password),
      );
      store.dispatch(AdminOtpSentAction(email: action.email));
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (e) {
      store.dispatch(LoginFailureAction(errorMessage: e.toString()));
    }
  }

  /// Step two: the code is exchanged for a session, which enters the store as
  /// an ordinary [LoginSuccessAction].
  Future<void> _handleAdminVerifyOtp(
    Store<AppState> store,
    AdminVerifyOtpAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final session = await verifyAdminOtpUseCase.call(
        VerifyAdminOtpParams(email: action.email, otpCode: action.otpCode),
      );
      store.dispatch(LoginSuccessAction(
        token: session.token,
        role: session.role,
        userName: session.userName,
      ));
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (e) {
      store.dispatch(LoginFailureAction(errorMessage: e.toString()));
    }
  }

  Future<void> _handleLogin(
    Store<AppState> store,
    LoginRequestAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final session = await loginUseCase.call(
        LoginParams(
          email: action.email,
          password: action.password,
          role: action.role,
        ),
      );
      store.dispatch(LoginSuccessAction(
        token: session.token,
        role: session.role,
        userName: session.userName,
      ));
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (e) {
      store.dispatch(LoginFailureAction(errorMessage: e.toString()));
    }
  }

  Future<void> _handleVerifyEmail(
    Store<AppState> store,
    VerifyEmailAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      // Only pharmacies verify. The endpoint must use `otp_code` because
      // `/verify-email` checks a different OTP purpose.
      final response = await sl<ApiClient>().dio.post(
        '/users/pharmacy/verify-otp',
        data: {
          'email': action.email,
          'otp_code': action.otp,
        },
      );

      if (response.statusCode == 200) {
        store.dispatch(const VerifyEmailSuccessAction());
      } else {
        throw const ServerFailure('Email verification failed');
      }
    } on Failure catch (failure) {
      store.dispatch(VerifyEmailFailureAction(errorMessage: failure.message));
    } on Exception catch (e) {
      store.dispatch(VerifyEmailFailureAction(errorMessage: e.toString()));
    }
  }

  Future<void> _handleForgotPassword(
    Store<AppState> store,
    ForgotPasswordRequestAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final response = await sl<ApiClient>().dio.post(
        '/users/forgot-password',
        data: {'email': action.email},
      );

      if (response.statusCode == 200) {
        store.dispatch(const ForgotPasswordSuccessAction(
          message:
              'If an account exists, a password reset link has been sent to your email.',
        ));
      } else {
        throw const ServerFailure('Password reset request failed');
      }
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (e) {
      store.dispatch(LoginFailureAction(errorMessage: e.toString()));
    }
  }

  Future<void> _handleRestoreSession(
    Store<AppState> store,
    RestoreSessionAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final session = await restoreSessionUseCase.call(NoParams());
      if (session != null) {
        store.dispatch(LoginSuccessAction(
          token: session.token,
          role: session.role,
          userName: session.userName,
        ));
      }
    } on Exception {
      store.dispatch(const SessionExpiredAction());
    }
  }

  Future<void> _handleLogout(
    Store<AppState> store,
    LogoutAction action,
    NextDispatcher next,
  ) async {
    // Clear the store first so the UI never waits on the network to sign out.
    next(action);
    try {
      await sl<AuthRepository>().logout();
    } catch (_) {
      // Storage failures included: the store is already cleared, and there is
      // nothing useful to show the user on a logout that mostly succeeded.
    }
  }
}

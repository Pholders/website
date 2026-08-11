import 'package:redux/redux.dart';

import '../../../app/app_state.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/usecases/usecase.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/restore_session_usecase.dart';

class AuthMiddleware {
  AuthMiddleware() {
    loginUseCase = LoginUseCase(sl());
    restoreSessionUseCase = RestoreSessionUseCase(sl());
  }

  late final LoginUseCase loginUseCase;
  late final RestoreSessionUseCase restoreSessionUseCase;

  List<Middleware<AppState>> get middleware => [
        TypedMiddleware<AppState, LoginRequestAction>(_handleLogin),
        TypedMiddleware<AppState, RestoreSessionAction>(_handleRestoreSession),
        TypedMiddleware<AppState, LogoutAction>(_handleLogout),
        TypedMiddleware<AppState, VerifyEmailAction>(_handleVerifyEmail),
        TypedMiddleware<AppState, ForgotPasswordRequestAction>(
            _handleForgotPassword),
      ];

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
      // Only pharmacies verify — doctor signup activates the account and never
      // issues a code. Must be /verify-otp with `otp_code`: /verify-email
      // checks a different OTP purpose and leaves `status` unchanged, which
      // locks the account out of login permanently.
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
      store.dispatch(SessionExpiredAction());
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

import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_reducer.dart';
import 'package:pholders_app/core/auth/auth_state.dart';

void main() {
  group('authReducer', () {
    test('ignores an empty restore-session action', () {
      final state =
          const AuthState(token: 'abc', role: 'doctor', userName: 'Ada');

      final nextState = authReducer(
        state,
        const RestoreSessionAction(token: '', role: '', userName: ''),
      );

      expect(nextState, state);
    });

    test('stores a signup success message and clears loading', () {
      final state = const AuthState(isLoading: true, errorMessage: 'old error');

      final nextState = authReducer(
        state,
        const SignupSuccessAction(
            message: 'Account created. Please verify your email.'),
      );

      expect(nextState.isLoading, isFalse);
      expect(nextState.errorMessage, isNull);
      expect(nextState.successMessage,
          'Account created. Please verify your email.');
    });
  });

  group('authReducer — admin sign-in', () {
    test('an emailed code does not authenticate the user', () {
      final nextState = authReducer(
        const AuthState(isLoading: true),
        const AdminOtpSentAction(email: 'ops@pholders.test'),
      );

      // The whole point: step one issues no token, so admin routes must stay
      // shut until the code is verified.
      expect(nextState.isAuthenticated, isFalse);
      expect(nextState.token, isNull);
      expect(nextState.role, isNull);
      expect(nextState.isLoading, isFalse);
      expect(nextState.successMessage, contains('ops@pholders.test'));
    });

    test('submitting admin credentials clears a previous error', () {
      final nextState = authReducer(
        const AuthState(errorMessage: 'Invalid email or password'),
        const AdminLoginRequestAction(
            email: 'ops@pholders.test', password: 'secret'),
      );

      expect(nextState.isLoading, isTrue);
      expect(nextState.errorMessage, isNull);
    });

    test('submitting the code clears the code-sent message', () {
      final nextState = authReducer(
        const AuthState(successMessage: 'We sent a 6-digit code to x@y.test.'),
        const AdminVerifyOtpAction(email: 'x@y.test', otpCode: '123456'),
      );

      expect(nextState.isLoading, isTrue);
      expect(nextState.successMessage, isNull);
    });

    test('a verified code authenticates as admin', () {
      final nextState = authReducer(
        const AuthState(isLoading: true),
        const LoginSuccessAction(
            token: 'jwt', role: 'admin', userName: 'Thabo Mokoena'),
      );

      expect(nextState.isAuthenticated, isTrue);
      expect(nextState.role, 'admin');
      expect(nextState.userName, 'Thabo Mokoena');
    });

    test('logout clears an admin session', () {
      final nextState = authReducer(
        const AuthState(token: 'jwt', role: 'admin', userName: 'Thabo'),
        const LogoutAction(),
      );

      expect(nextState.isAuthenticated, isFalse);
      expect(nextState.token, isNull);
      expect(nextState.role, isNull);
    });
  });
}

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
}

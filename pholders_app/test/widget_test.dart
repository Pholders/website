import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_reducer.dart';
import 'package:pholders_app/core/auth/auth_state.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';

void main() {
  group('Doctor.fromJson', () {
    // The real payload from POST /users/doctor/login — camelCase, and the
    // doctor's id arrives as `doctorId`.
    test('parses the camelCase login payload', () {
      final doctor = Doctor.fromJson(const {
        'token': 'jwt',
        'doctorId': 3,
        'firstName': 'Claude',
        'lastName': 'Testdoc',
        'email': 'claude.testdoc.integration@pholders.test',
        'hpcsaNumber': 'MP-9911234',
      });

      expect(doctor.id, 3);
      expect(doctor.firstName, 'Claude');
      expect(doctor.hpcsaNumber, 'MP-9911234');
      expect(doctor.fullName, 'Claude Testdoc');
      expect(doctor.displayName, 'Dr Claude Testdoc');
    });

    // The real payload from GET /users/doctor/profile — snake_case, and
    // Postgres NUMERIC columns come back as strings.
    test('parses the snake_case profile payload', () {
      final doctor = Doctor.fromJson(const {
        'id': 3,
        'first_name': 'Claude',
        'last_name': 'Testdoc',
        'email': 'claude.testdoc.integration@pholders.test',
        'hpcsa_number': 'MP-9911234',
        'experience': 5,
        'clinic_name': 'Integration Test Clinic',
        'consultation_fee': '350.00',
        'rating': null,
        'review_count': 0,
        'email_verified': false,
        'status': 'active',
      });

      expect(doctor.id, 3);
      expect(doctor.clinicName, 'Integration Test Clinic');
      // Arrives as the string "350.00", not a number.
      expect(doctor.consultationFee, 350.0);
      expect(doctor.rating, isNull);
      expect(doctor.emailVerified, isFalse);
    });

    test('falls back to the email local part when the name is missing', () {
      final doctor = Doctor.fromJson(const {'id': 1, 'email': 'dr.who@x.test'});
      expect(doctor.fullName, 'dr.who');
    });
  });

  group('authReducer', () {
    test('LoginSuccessAction ends both loading and restoring', () {
      final state = authReducer(
        AuthState.initial().copyWith(isLoading: true),
        const LoginSuccessAction(
          token: 'jwt',
          role: 'doctor',
          userName: 'Claude Testdoc',
        ),
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.isDoctor, isTrue);
      expect(state.isLoading, isFalse);
      // The router guard blocks on isRestoring, so a login must clear it.
      expect(state.isRestoring, isFalse);
    });

    test('LoginFailureAction keeps the user signed out and shows the error', () {
      final state = authReducer(
        AuthState.initial().copyWith(isLoading: true),
        const LoginFailureAction(errorMessage: 'Invalid email or password'),
      );

      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Invalid email or password');
    });

    test('logging out does not leave the router stuck on isRestoring', () {
      final signedIn = authReducer(
        AuthState.initial(),
        const LoginSuccessAction(token: 't', role: 'doctor', userName: 'C'),
      );
      final state = authReducer(signedIn, const LogoutAction());

      expect(state.isAuthenticated, isFalse);
      expect(state.token, isNull);
      expect(state.isRestoring, isFalse);
    });

    test('NoStoredSessionAction releases the router on a cold start', () {
      final state = authReducer(
        AuthState.initial(),
        const NoStoredSessionAction(),
      );

      expect(state.isRestoring, isFalse);
      expect(state.isAuthenticated, isFalse);
    });
  });
}

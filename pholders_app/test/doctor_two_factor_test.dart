import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_middleware.dart';
import 'package:pholders_app/core/auth/inactivity_watcher.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/features/auth/data/pharmacy_auth_repository.dart';
import 'package:pholders_app/features/auth/presentation/widgets/login_panel.dart';
import 'package:pholders_app/shared/constants/app_constants.dart';

/// Two-factor sign-in and the 30-minute inactivity sign-out (agreed with the
/// team on 2026-11-24/25).

class _MemoryStorage extends TokenStorage {
  _MemoryStorage() : super(const FlutterSecureStorage());

  String? token;
  String? role;
  final trusted = <String, String>{};
  DateTime? lastActive;
  bool cleared = false;

  @override
  Future<String?> readToken() async => token;
  @override
  Future<String?> readRole() async => role;
  @override
  Future<String?> readUserName() async => 'Dr Test';
  @override
  Future<void> saveSession({
    required String token,
    required String role,
    required String userName,
  }) async {
    this.token = token;
    this.role = role;
  }

  @override
  Future<void> rememberEmail(String? email) async {}
  @override
  Future<String?> readTrustedDeviceToken(String email) async =>
      trusted[email.toLowerCase()];
  @override
  Future<void> saveTrustedDeviceToken(String email, String token) async =>
      trusted[email.toLowerCase()] = token;
  @override
  Future<DateTime?> readLastActive() async => lastActive;
  @override
  Future<void> saveLastActive(DateTime when) async => lastActive = when;
  @override
  Future<void> clear() async {
    cleared = true;
    token = null;
    role = null;
    lastActive = null;
  }
}

const _doctor = Doctor(id: 1, firstName: 'Thandi', lastName: 'Nkosi', email: 'dr@x.test');

class _Doctors extends DoctorAuthRepository {
  _Doctors(TokenStorage storage, {this.twoFa = false})
      : super(ApiClient(tokenStorage: storage));

  final bool twoFa;
  final calls = <String>[];
  String? sentTrusted;
  bool wrongCode = false;

  @override
  Future<DoctorSession> login({
    required String email,
    required String password,
    String? trustedDeviceToken,
  }) async {
    calls.add('login');
    sentTrusted = trustedDeviceToken;
    if (twoFa && trustedDeviceToken != 'trusted-today') {
      throw TwoFactorRequired(email: email);
    }
    return const DoctorSession(token: 'doctor-token', doctor: _doctor);
  }

  @override
  Future<DoctorSession> verifyLoginCode({
    required String email,
    required String code,
  }) async {
    calls.add('verify $code');
    if (wrongCode) {
      throw const ApiException(
          message: 'That code is wrong or has expired.',
          statusCode: 401,
          kind: ApiErrorKind.http);
    }
    return const DoctorSession(
        token: 'doctor-token', doctor: _doctor, trustedDeviceToken: 'trusted-today');
  }

  @override
  Future<Doctor> fetchProfile() async => _doctor;

  @override
  Future<void> logout() async => calls.add('server logout');
}

class _Pharmacies extends PharmacyAuthRepository {
  _Pharmacies(TokenStorage storage) : super(ApiClient(tokenStorage: storage));
  int logins = 0;

  @override
  Future<PharmacySession> login({required String email, required String password}) async {
    logins++;
    throw const ApiException(message: 'no', statusCode: 401, kind: ApiErrorKind.http);
  }
}

({Store<AppState> store, _Doctors doctors, _Pharmacies pharmacies, _MemoryStorage storage})
    _harness({bool twoFa = false}) {
  final storage = _MemoryStorage();
  final doctors = _Doctors(storage, twoFa: twoFa);
  final pharmacies = _Pharmacies(storage);
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: createAuthMiddleware(
      doctorAuth: doctors,
      pharmacyAuth: pharmacies,
      tokenStorage: storage,
    ),
  );
  return (store: store, doctors: doctors, pharmacies: pharmacies, storage: storage);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('two-factor sign-in', () {
    test('a right password with 2FA on asks for the code, not the pharmacy login',
        () async {
      final h = _harness(twoFa: true);
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();

      final auth = h.store.state.authState;
      expect(auth.pendingCodeEmail, 'dr@x.test');
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isSigningIn, isFalse, reason: 'back to the form from the splash');
      expect(h.pharmacies.logins, 0);
    });

    test('the right code signs in and remembers this browser for today',
        () async {
      final h = _harness(twoFa: true);
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();
      h.store.dispatch(const VerifyLoginCodeAction(email: 'dr@x.test', code: '123456'));
      await _settle();

      final auth = h.store.state.authState;
      expect(auth.isAuthenticated, isTrue);
      expect(auth.pendingCodeEmail, isNull);
      expect(h.storage.trusted['dr@x.test'], 'trusted-today');
      expect(h.storage.lastActive, isNotNull);

      // The next sign-in on this browser sends the token and needs no code.
      h.store.dispatch(const LogoutAction());
      await _settle();
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();
      expect(h.doctors.sentTrusted, 'trusted-today');
      expect(h.store.state.authState.isAuthenticated, isTrue);
    });

    test('a wrong code stays on the code step and says why', () async {
      final h = _harness(twoFa: true)..doctors.wrongCode = true;
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();
      h.store.dispatch(const VerifyLoginCodeAction(email: 'dr@x.test', code: '000000'));
      await _settle();

      final auth = h.store.state.authState;
      expect(auth.isAuthenticated, isFalse);
      expect(auth.pendingCodeEmail, 'dr@x.test');
      expect(auth.errorMessage, 'That code is wrong or has expired.');
    });

    test('Back leaves the code step', () async {
      final h = _harness(twoFa: true);
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();
      h.store.dispatch(const CancelLoginCodeAction());
      expect(h.store.state.authState.pendingCodeEmail, isNull);
    });
  });

  group('signing out', () {
    test('ends the session on the server before forgetting it', () async {
      final h = _harness();
      h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
      await _settle();
      h.store.dispatch(const LogoutAction());
      await _settle();
      expect(h.doctors.calls, contains('server logout'),
          reason: 'the role was read after the reducer cleared it, so this never ran');
      expect(h.storage.cleared, isTrue);
    });

    test('a doctor tab reopened after 30 idle minutes starts signed out',
        () async {
      final h = _harness();
      h.storage
        ..token = 'old-token'
        ..role = AppConstants.roleDoctor
        ..lastActive = DateTime.now().subtract(const Duration(minutes: 31));
      h.store.dispatch(const AppStartedAction());
      await _settle();

      expect(h.store.state.authState.isAuthenticated, isFalse);
      expect(h.store.state.authState.errorMessage, contains('30 minutes'));
      expect(h.doctors.calls, contains('server logout'));
    });

    test('a tab reopened within 30 minutes keeps its session', () async {
      final h = _harness();
      h.storage
        ..token = 'old-token'
        ..role = AppConstants.roleDoctor
        ..lastActive = DateTime.now().subtract(const Duration(minutes: 5));
      h.store.dispatch(const AppStartedAction());
      await _settle();
      expect(h.store.state.authState.isAuthenticated, isTrue);
    });
  });

  group('InactivityWatcher', () {
    Future<({_MemoryStorage storage, List<Object> dispatched, void Function(Duration) advance})>
        pump(WidgetTester tester) async {
      var now = DateTime(2026, 11, 25, 9);
      final storage = _MemoryStorage();
      final dispatched = <Object>[];
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: [
          (store, action, next) {
            dispatched.add(action);
            next(action);
          },
        ],
      );
      store.dispatch(const RestoreSessionAction(
          token: 't', role: AppConstants.roleDoctor, userName: 'Dr Test'));
      dispatched.clear();
      await tester.pumpWidget(InactivityWatcher(
        store: store,
        storage: storage,
        clock: () => now,
        checkEvery: const Duration(seconds: 1),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(),
        ),
      ));
      return (
        storage: storage,
        dispatched: dispatched,
        advance: (d) => now = now.add(d),
      );
    }

    testWidgets('signs a doctor out after 30 minutes without activity',
        (tester) async {
      final w = await pump(tester);
      w.advance(const Duration(minutes: 29));
      await tester.pump(const Duration(seconds: 2));
      expect(w.dispatched.whereType<InactivityLogoutAction>(), isEmpty);

      w.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(w.dispatched.whereType<InactivityLogoutAction>(), hasLength(1));
    });

    testWidgets('a click restarts the 30 minutes', (tester) async {
      final w = await pump(tester);
      w.advance(const Duration(minutes: 25));
      await tester.tapAt(const Offset(10, 10));
      w.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 2));
      expect(w.dispatched.whereType<InactivityLogoutAction>(), isEmpty);
      expect(w.storage.lastActive, isNotNull,
          reason: 'shared with other tabs and with start-up');
    });

    testWidgets('an idle tab does not sign out a doctor busy in another tab',
        (tester) async {
      final w = await pump(tester);
      w.advance(const Duration(minutes: 31));
      w.storage.lastActive = DateTime(2026, 11, 25, 9, 30); // the other tab
      await tester.pump(const Duration(seconds: 2));
      expect(w.dispatched.whereType<InactivityLogoutAction>(), isEmpty);
    });
  });

  testWidgets('the login form shows the code step and sends the code',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = _harness(twoFa: true);
    await tester.pumpWidget(StoreProvider<AppState>(
      store: h.store,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginPanel(fieldWidth: 360, storage: h.storage),
          ),
        ),
      ),
    ));
    h.store.dispatch(const LoginRequestAction(email: 'dr@x.test', password: 'pw'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('dr@x.test'), findsOneWidget);

    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('login-code')),
            matching: find.byType(TextField)),
        '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(h.doctors.calls, contains('verify 123456'));
    expect(h.store.state.authState.isAuthenticated, isTrue);
  });
}

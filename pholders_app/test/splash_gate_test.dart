import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_reducer.dart';
import 'package:pholders_app/core/auth/auth_state.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/shared/widgets/splash_gate.dart';
import 'package:pholders_app/shared/widgets/splash_view.dart';
import 'package:redux/redux.dart';

/// The splash screen is the loader while a session starts: at startup while
/// the stored session is read, and after signing in until a doctor's
/// appointments are in. It never traps anyone, and does not come back for
/// later reloads.
void main() {
  late Store<AppState> store;
  late List<Object> seen;

  Future<void> show(WidgetTester tester) async {
    seen = [];
    store = Store<AppState>(
      (state, action) {
        seen.add(action);
        return appReducer(state, action);
      },
      initialState: AppState.initial(),
    );
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        builder: (context, child) => SplashGate(child: child!),
        home: const Scaffold(body: Text('The page')),
      ),
    ));
  }

  Future<void> settle(WidgetTester tester,
      [Duration by = Duration.zero]) async {
    await tester.pump();
    await tester.pump(by);
    await tester.pump(const Duration(milliseconds: 400)); // the fade
  }

  bool splash() => find.byType(SplashView).evaluate().isNotEmpty;

  void signInAsDoctor() => store.dispatch(const LoginSuccessAction(
      token: 'doctor-token', role: 'doctor', userName: 'Thandi Nkosi'));

  testWidgets('it covers startup, and lifts at once when no one is signed in',
      (tester) async {
    await show(tester);
    expect(splash(), isTrue);
    // The page builds underneath, so it can fetch while covered.
    expect(find.text('The page'), findsOneWidget);

    store.dispatch(const NoStoredSessionAction());
    await settle(tester);
    expect(splash(), isFalse);
  });

  testWidgets("after a doctor signs in it stays until the appointments land",
      (tester) async {
    await show(tester);
    store.dispatch(const NoStoredSessionAction());
    await settle(tester);

    signInAsDoctor();
    await settle(tester, const Duration(seconds: 5));
    expect(splash(), isTrue);

    store.dispatch(const AppointmentsLoadedAction(appointments: []));
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isFalse);

    // A later reload does not bring it back.
    store.dispatch(const LoadAppointmentsAction());
    await settle(tester);
    expect(splash(), isFalse);
  });

  testWidgets('a quick load still shows it long enough not to flicker',
      (tester) async {
    await show(tester);
    store.dispatch(const NoStoredSessionAction());
    await settle(tester);

    signInAsDoctor();
    await tester.pump();
    store.dispatch(const AppointmentsLoadedAction(appointments: []));
    await tester.pump(const Duration(milliseconds: 500));
    expect(splash(), isTrue);
    await settle(tester, const Duration(seconds: 1));
    expect(splash(), isFalse);
  });

  testWidgets('a failed load lifts it, so the page can show the problem',
      (tester) async {
    await show(tester);
    store.dispatch(const RestoreSessionAction(
        token: 't', role: 'doctor', userName: 'Thandi Nkosi'));
    await settle(tester);
    expect(splash(), isTrue);

    store.dispatch(const AppointmentsLoadFailedAction(errorMessage: 'Offline'));
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isFalse);
  });

  testWidgets('if no page asks for the data, it asks itself', (tester) async {
    await show(tester);
    signInAsDoctor();
    await settle(tester);
    expect(seen.whereType<LoadAppointmentsAction>(), hasLength(1));
  });

  testWidgets('it gives up waiting rather than trap anyone', (tester) async {
    await show(tester);
    signInAsDoctor();
    await settle(tester, const Duration(seconds: 16));
    expect(splash(), isFalse);
  });

  testWidgets('a pharmacy sees it briefly as they sign in', (tester) async {
    await show(tester);
    store.dispatch(const NoStoredSessionAction());
    await settle(tester);

    store.dispatch(const LoginSuccessAction(
        token: 'p', role: 'pharmacy', userName: 'Corner Pharmacy'));
    await tester.pump();
    await tester.pump();
    expect(splash(), isTrue);
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isFalse);
  });

  testWidgets('it shows again for the next sign-in after logging out',
      (tester) async {
    await show(tester);
    signInAsDoctor();
    store.dispatch(const AppointmentsLoadedAction(appointments: []));
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isFalse);

    store.dispatch(const LogoutAction());
    await settle(tester);
    store.dispatch(const LoginSuccessAction(
        token: 'second-token', role: 'doctor', userName: 'Thandi Nkosi'));
    await settle(tester);
    expect(splash(), isTrue);
  });

  testWidgets('it is the loader while a login is answered', (tester) async {
    await show(tester);
    store.dispatch(const NoStoredSessionAction());
    await settle(tester);

    store.dispatch(const LoginRequestAction(email: 'a@b.c', password: 'pw'));
    await settle(tester);
    expect(splash(), isTrue);

    // A login that fails is back on the form at once, with its message.
    store.dispatch(const LoginFailureAction(errorMessage: 'Wrong password'));
    await settle(tester);
    expect(splash(), isFalse);
    expect(store.state.authState.errorMessage, 'Wrong password');
  });

  test('signing in is its own flag, cleared however the login ends', () {
    const ask = LoginRequestAction(email: 'a@b.c', password: 'pw');
    final asking = authReducer(const AuthState(isRestoring: false), ask);
    expect(asking.isSigningIn, isTrue);

    expect(
        authReducer(
                asking,
                const LoginSuccessAction(
                    token: 't', role: 'doctor', userName: 'T'))
            .isSigningIn,
        isFalse);
    expect(
        authReducer(asking, const LoginFailureAction(errorMessage: 'No'))
            .isSigningIn,
        isFalse);
  });

  Future<void> signedInDoctor(WidgetTester tester) async {
    await show(tester);
    signInAsDoctor();
    store.dispatch(const AppointmentsLoadedAction(appointments: []));
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isFalse);
  }

  testWidgets('signing out shows it until the server has ended the session',
      (tester) async {
    await signedInDoctor(tester);

    store.dispatch(const LogoutAction());
    await settle(tester, const Duration(seconds: 2));
    expect(splash(), isTrue);

    store.dispatch(const LogoutCompletedAction());
    await settle(tester);
    expect(splash(), isFalse);
  });

  testWidgets('a quick sign-out still shows it long enough not to flicker',
      (tester) async {
    await signedInDoctor(tester);

    store.dispatch(const LogoutAction());
    await tester.pump();
    store.dispatch(const LogoutCompletedAction());
    await tester.pump(const Duration(milliseconds: 500));
    expect(splash(), isTrue);
    await settle(tester, const Duration(seconds: 1));
    expect(splash(), isFalse);
  });

  testWidgets('a server that never answers does not keep it up',
      (tester) async {
    await signedInDoctor(tester);

    store.dispatch(const LogoutAction());
    await settle(tester, const Duration(seconds: 6));
    expect(splash(), isFalse);
  });

  testWidgets('an expired session goes straight to the login page',
      (tester) async {
    await signedInDoctor(tester);

    store.dispatch(const SessionExpiredAction());
    await settle(tester);
    expect(splash(), isFalse);
  });
}

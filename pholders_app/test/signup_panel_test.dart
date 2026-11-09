import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/auth/presentation/widgets/signup_panel.dart';
import 'package:redux/redux.dart';

/// Step 1 of signing up: the details, checked, then carried to step 2.
void main() {
  late Store<AppState> store;

  Future<void> show(WidgetTester tester,
      {bool compact = false, Size size = const Size(1200, 1400)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/register', routes: [
      GoRoute(
        path: '/register',
        builder: (_, __) => Scaffold(
          body: SingleChildScrollView(child: SignupPanel(compact: compact)),
        ),
      ),
      GoRoute(
        path: '/register/step-2',
        builder: (_, __) => const Text('Step 2'),
      ),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
    ]);
    store = Store<AppState>(appReducer, initialState: AppState.initial());
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('it says what is missing, field by field', (tester) async {
    await show(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Step 2'), findsNothing);

    // Each message goes as its field is put right.
    await tester.enterText(field('First name'), 'Thandi');
    await tester.pump();
    expect(find.text('Enter your first name'), findsNothing);
  });

  Future<void> fillStep1(WidgetTester tester) async {
    await tester.enterText(field('First name'), 'Thandi');
    await tester.enterText(field('Last name'), 'Nkosi');
    await tester.enterText(field('Phone number'), '0821234567');
    await tester.enterText(field('Email address'), 'thandi@example.com');
    await tester.enterText(field('Password'), 'Str0ng!pass');
    await tester.enterText(field('Confirm password'), 'Str0ng!pass');
    await tester.pump();
  }

  testWidgets('good details bring step 2 into the same place', (tester) async {
    await show(tester);
    await fillStep1(tester);
    // The confirmation matches.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // No new page: step 2 shows where step 1 was, with step 1's name in it.
    expect(find.text('Step 2'), findsNothing);
    expect(find.text('Tell us about your practice'), findsOneWidget);
    expect(find.textContaining('Thandi, one more step after this'),
        findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
  });

  testWidgets("once created, step 3 (the code) takes step 2's place",
      (tester) async {
    await show(tester);
    await fillStep1(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Step 2 of 3', findRichText: true), findsOneWidget);

    // The signup call succeeds.
    store
        .dispatch(const DoctorSignupSuccessAction(email: 'thandi@example.com'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Step 3 of 3', findRichText: true), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('thandi@example.com'), findsOneWidget);
    expect(find.text('Tell us about your practice'), findsNothing);
  });

  testWidgets('back from step 2 keeps what was typed', (tester) async {
    await show(tester);
    await fillStep1(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('thandi@example.com'), findsOneWidget);
  });

  testWidgets('passwords that differ are caught', (tester) async {
    await show(tester);
    await tester.enterText(field('Password'), 'one-password');
    await tester.enterText(field('Confirm password'), 'another');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match'), findsOneWidget);
  });

  testWidgets('the strength meter reads the password', (tester) async {
    await show(tester);
    expect(find.text('Password strength'), findsOneWidget);
    await tester.enterText(field('Password'), 'abc');
    await tester.pump();
    expect(find.text('Weak'), findsOneWidget);
    await tester.enterText(field('Password'), 'Longer-Pass-2024');
    await tester.pump();
    expect(find.text('Strong'), findsOneWidget);
  });

  testWidgets('a pharmacy gets its own step 2', (tester) async {
    await show(tester);
    await tester.tap(find.text('Pharmacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dispense prescriptions'), findsOneWidget);
    await fillStep1(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Tell us about your pharmacy'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Licence number'), findsOneWidget);
    expect(find.text('Tell us about your practice'), findsNothing);
  });

  testWidgets('it leads to logging in instead', (tester) async {
    await show(tester);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Login page'), findsOneWidget);
  });

  testWidgets('on a phone it is one column', (tester) async {
    await show(tester, compact: true, size: const Size(360, 1400));
    final first = tester.getTopLeft(field('First name'));
    final last = tester.getTopLeft(field('Last name'));
    expect(last.dy, greaterThan(first.dy));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_state.dart';
import 'package:pholders_app/features/auth/data/models/doctor_registration_draft.dart';
import 'package:pholders_app/features/auth/presentation/doctor_register_step2_page.dart';
import 'package:pholders_app/features/auth/presentation/verify_account_page.dart';
import 'package:pholders_app/shared/constants/sa_locations.dart';
import 'package:redux/redux.dart';

/// Step 2 of signing up (the practice) and verifying the account, in the
/// same card as step 1.
void main() {
  late List<Object> dispatched;

  const draft = DoctorRegistrationDraft(
    firstName: 'Thandi',
    lastName: 'Nkosi',
    email: 'thandi@example.com',
    phone: '0821234567',
    password: 'Str0ng!pass',
  );

  Future<void> show(WidgetTester tester, Widget page,
      {AuthState auth = const AuthState(isRestoring: false)}) async {
    dispatched = [];
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final base = AppState.initial();
    final store = Store<AppState>(
      (state, action) {
        dispatched.add(action as Object);
        return state;
      },
      initialState: AppState(
        authState: auth,
        appointmentsState: base.appointmentsState,
        prescriptionsState: base.prescriptionsState,
        reviewsState: base.reviewsState,
        dispensingState: base.dispensingState,
        pharmacyOrdersState: base.pharmacyOrdersState,
      ),
    );
    final router = GoRouter(initialLocation: '/page', routes: [
      GoRoute(path: '/page', builder: (_, __) => page),
      GoRoute(path: '/register', builder: (_, __) => const Text('Step 1')),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
    ]);
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('Step 2', () {
    testWidgets('without step 1 it sends you back to start', (tester) async {
      await show(tester, const DoctorRegisterStep2Page());
      expect(find.text('Start from the beginning'), findsOneWidget);
      await tester.tap(find.text('Back to step 1'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('it says what is missing before submitting', (tester) async {
      await show(tester, const DoctorRegisterStep2Page(draft: draft));
      expect(find.textContaining('Step 2 of 3', findRichText: true),
          findsOneWidget);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your HPCSA number'), findsOneWidget);
      expect(find.text('Choose your province'), findsOneWidget);
      expect(dispatched.whereType<DoctorSignupRequestAction>(), isEmpty);
    });

    testWidgets('both steps go in one signup', (tester) async {
      await show(tester, const DoctorRegisterStep2Page(draft: draft));
      await tester.enterText(field('HPCSA number'), 'MP0123456');
      await tester.enterText(field('Years of experience'), '7');
      await tester.enterText(field('Specialization'), 'General Practice');
      await tester.enterText(field('Clinic or practice name'), 'Nkosi Clinic');

      await tester.tap(find.text('Province'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gauteng').last);
      await tester.pumpAndSettle();
      final city = SaLocations.citiesFor('Gauteng').first;
      await tester.tap(find.text('City'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(city).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      final sent = dispatched.whereType<DoctorSignupRequestAction>().single;
      expect(sent.email, draft.email);
      expect(sent.hpcsaNumber, 'MP0123456');
      expect(sent.experience, 7);
      expect(sent.province, 'Gauteng');
      expect(sent.city, city);
    });

    testWidgets("the server's problem is shown", (tester) async {
      await show(tester, const DoctorRegisterStep2Page(draft: draft),
          auth: const AuthState(
              isRestoring: false, errorMessage: 'Email already registered'));
      expect(find.text('Email already registered'), findsOneWidget);
    });
  });

  group('Verify', () {
    const waiting =
        AuthState(isRestoring: false, signupEmail: 'thandi@example.com');

    testWidgets('it names the address the code went to', (tester) async {
      await show(tester, const VerifyAccountPage(), auth: waiting);
      expect(find.textContaining('Step 3 of 3', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('thandi@example.com'), findsOneWidget);
    });

    testWidgets('a pasted code fills the boxes and verifies', (tester) async {
      await show(tester, const VerifyAccountPage(), auth: waiting);
      await tester.enterText(find.byType(TextField).first, '482913');
      await tester.pumpAndSettle();
      final sent = dispatched.whereType<VerifyEmailRequestAction>().single;
      expect(sent.otpCode, '482913');
      expect(sent.email, 'thandi@example.com');
    });

    testWidgets('typing moves along the boxes', (tester) async {
      await show(tester, const VerifyAccountPage(), auth: waiting);
      final boxes = find.byType(TextField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(boxes.at(i), '${i + 1}');
        await tester.pump();
      }
      expect(dispatched.whereType<VerifyEmailRequestAction>().single.otpCode,
          '123456');
    });

    testWidgets('the code can be sent again', (tester) async {
      await show(tester, const VerifyAccountPage(), auth: waiting);
      await tester.tap(find.text('Send it again'));
      await tester.pumpAndSettle();
      expect(
          dispatched.whereType<RequestVerificationOtpAction>(), hasLength(1));
      expect(find.text('A new code is on its way.'), findsOneWidget);
    });

    testWidgets('after a refresh it points to signing in', (tester) async {
      await show(tester, const VerifyAccountPage());
      expect(find.text('Go to sign in'), findsOneWidget);
      await tester.tap(find.text('Go to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Login page'), findsOneWidget);
    });
  });
}

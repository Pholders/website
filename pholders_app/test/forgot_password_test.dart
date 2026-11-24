import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';
import 'package:pholders_app/features/auth/presentation/forgot_password_page.dart';

/// Records what the page asks the server for.
class _FakeRepo implements DoctorAuthRepository {
  final calls = <String>[];
  ApiException? resetFailure;

  @override
  Future<String> requestPasswordReset({required String email}) async {
    calls.add('request $email');
    return 'If a doctor account exists for this email, a 6-digit reset code has been sent.';
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    calls.add('reset $email $code $newPassword');
    if (resetFailure != null) throw resetFailure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _show(WidgetTester tester, _FakeRepo repo) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => ForgotPasswordPage(repository: repo),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('login screen')),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sending the code calls the server instead of leaving the page',
      (tester) async {
    final repo = _FakeRepo();
    await _show(tester, repo);

    await tester.enterText(
        find.byKey(const ValueKey('reset-email')).last, 'dr@pholders.test');
    await tester.tap(find.text('Send Reset Code'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['request dr@pholders.test']);
    expect(find.text('login screen'), findsNothing);
    expect(find.text('Reset Password'), findsWidgets);
    expect(find.textContaining('dr@pholders.test'), findsWidgets);
  });

  testWidgets('a bad email is caught before anything is sent', (tester) async {
    final repo = _FakeRepo();
    await _show(tester, repo);

    await tester.enterText(
        find.byKey(const ValueKey('reset-email')).last, 'not an email');
    await tester.tap(find.text('Send Reset Code'));
    await tester.pumpAndSettle();

    expect(repo.calls, isEmpty);
    expect(find.text('Enter the email address you sign in with.'),
        findsOneWidget);
  });

  testWidgets('the code and new password reset it and go to login',
      (tester) async {
    final repo = _FakeRepo();
    await _show(tester, repo);
    await tester.enterText(
        find.byKey(const ValueKey('reset-email')).last, 'dr@pholders.test');
    await tester.tap(find.text('Send Reset Code'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('reset-code')).last, '123456');
    await tester.enterText(
        find.byKey(const ValueKey('reset-password')).last, 'NewPass!2026');
    await tester.enterText(
        find.byKey(const ValueKey('reset-confirm')).last, 'NewPass!2026');
    await tester.tap(find.text('Reset Password').last);
    await tester.pumpAndSettle();

    expect(repo.calls.last, 'reset dr@pholders.test 123456 NewPass!2026');
    expect(find.text('login screen'), findsOneWidget);
  });

  testWidgets('a wrong code stays on the page and says why', (tester) async {
    final repo = _FakeRepo()
      ..resetFailure = const ApiException(
        message: 'That code is wrong or has expired.',
        statusCode: 400,
        kind: ApiErrorKind.http,
      );
    await _show(tester, repo);
    await tester.enterText(
        find.byKey(const ValueKey('reset-email')).last, 'dr@pholders.test');
    await tester.tap(find.text('Send Reset Code'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('reset-code')).last, '000000');
    await tester.enterText(
        find.byKey(const ValueKey('reset-password')).last, 'NewPass!2026');
    await tester.enterText(
        find.byKey(const ValueKey('reset-confirm')).last, 'NewPass!2026');
    await tester.tap(find.text('Reset Password').last);
    await tester.pumpAndSettle();

    expect(find.text('That code is wrong or has expired.'), findsOneWidget);
    expect(find.text('login screen'), findsNothing);
  });

  testWidgets('mismatched passwords are caught before anything is sent',
      (tester) async {
    final repo = _FakeRepo();
    await _show(tester, repo);
    await tester.enterText(
        find.byKey(const ValueKey('reset-email')).last, 'dr@pholders.test');
    await tester.tap(find.text('Send Reset Code'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('reset-code')).last, '123456');
    await tester.enterText(
        find.byKey(const ValueKey('reset-password')).last, 'NewPass!2026');
    await tester.enterText(
        find.byKey(const ValueKey('reset-confirm')).last, 'Other!2026');
    await tester.tap(find.text('Reset Password').last);
    await tester.pumpAndSettle();

    expect(repo.calls, ['request dr@pholders.test']);
    expect(find.text('The two passwords do not match.'), findsOneWidget);
  });
}

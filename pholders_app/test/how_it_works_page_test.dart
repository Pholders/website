import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/features/public/presentation/how_it_works_page.dart';

/// The How it works page used to read "How It Works — To be implemented".
void main() {
  Future<void> show(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/how-it-works', routes: [
      GoRoute(
          path: '/how-it-works', builder: (_, __) => const HowItWorksPage()),
      GoRoute(path: '/services', builder: (_, __) => const Text('Services')),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
      GoRoute(
          path: '/register', builder: (_, __) => const Text('Register page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find.byType(Scrollable).first;

  testWidgets('the walkthrough opens on the first step and moves on',
      (tester) async {
    await show(tester, const Size(1440, 1000));
    expect(find.textContaining('To be implemented'), findsNothing);
    expect(find.text('Step 1 of 7 · Patient'), findsOneWidget);

    await tester.scrollUntilVisible(find.byTooltip('Next step'), 300,
        scrollable: scrollable());
    await tester.tap(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 7 · Doctor'), findsOneWidget);
    // Its screen: a booking waiting to be accepted.
    expect(find.text('Accept'), findsOneWidget);
  });

  testWidgets('choosing a step shows it', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Signs it').last, 300,
        scrollable: scrollable());
    await tester.tap(find.text('Signs it').last);
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 7 · Doctor'), findsOneWidget);
    expect(find.text('A signed prescription cannot be edited'), findsOneWidget);
    expect(find.text('Signed'), findsOneWidget);
  });

  testWidgets('each role has its own part', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Pharmacies'), 300,
        scrollable: scrollable());
    await tester.tap(find.text('Pharmacies'));
    await tester.pumpAndSettle();
    expect(find.text('Receive prescriptions'), findsOneWidget);
  });

  testWidgets('it lays out on a phone', (tester) async {
    await show(tester, const Size(360, 780));
    await tester.scrollUntilVisible(find.text('Create an account'), 400,
        scrollable: scrollable());
    expect(find.text('Create an account'), findsOneWidget);
  });
}

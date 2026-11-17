import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/features/public/presentation/about_page.dart';

/// The About page used to read "About — To be implemented".
void main() {
  Future<void> show(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/about', routes: [
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/features', builder: (_, __) => const Text('Features')),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
      GoRoute(
          path: '/register', builder: (_, __) => const Text('Register page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find.byType(Scrollable).first;

  testWidgets('it says why PHolders exists and what it holds to',
      (tester) async {
    await show(tester, const Size(1440, 1000));
    expect(find.textContaining('To be implemented'), findsNothing);
    expect(find.text('paper trail.'), findsOneWidget);
    expect(find.text('OUR MISSION'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('With PHolders'), 300,
        scrollable: scrollable());
    expect(find.text('On paper'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('The patient decides'), 300,
        scrollable: scrollable());
    expect(find.text('Only what is recorded'), findsOneWidget);
  });

  testWidgets('it leads on to the features', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('See every feature'), 300,
        scrollable: scrollable());
    await tester.tap(find.text('See every feature'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('it lays out on a phone', (tester) async {
    await show(tester, const Size(360, 780));
    await tester.scrollUntilVisible(find.text('Create an account'), 400,
        scrollable: scrollable());
    expect(find.text('Create an account'), findsOneWidget);
  });
}

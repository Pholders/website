import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/features/public/presentation/services_page.dart';

/// The Services page used to read "Services — To be implemented".
void main() {
  Future<void> show(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/services', routes: [
      GoRoute(path: '/services', builder: (_, __) => const ServicesPage()),
      GoRoute(path: '/features', builder: (_, __) => const Text('Features')),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
      GoRoute(
          path: '/register', builder: (_, __) => const Text('Register page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find.byType(Scrollable).first;

  testWidgets('it lists the four services', (tester) async {
    await show(tester, const Size(1440, 1000));
    expect(find.textContaining('To be implemented'), findsNothing);
    for (final s in [
      'Digital prescribing',
      'Consented health records',
      'Appointments and consultations',
      'Pharmacy dispensing',
    ]) {
      // In the fanned cards at the top, and as a section.
      expect(find.text(s), findsNWidgets(2));
    }
    // The linked services connect to nothing yet, so none is offered.
    expect(find.textContaining('Discovery'), findsNothing);
  });

  testWidgets('a question opens to its answer', (tester) async {
    await show(tester, const Size(1440, 1000));
    const q = 'Can a signed prescription be changed?';
    await tester.scrollUntilVisible(find.text(q), 300,
        scrollable: scrollable());
    expect(find.textContaining('Signing fixes it'), findsNothing);
    await tester.tap(find.text(q));
    await tester.pumpAndSettle();
    expect(find.textContaining('Signing fixes it'), findsOneWidget);
  });

  testWidgets('getting started leads to signing up', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Sign up now'), 300,
        scrollable: scrollable());
    await tester.tap(find.text('Sign up now'));
    await tester.pumpAndSettle();
    expect(find.text('Register page'), findsOneWidget);
  });

  testWidgets('it lays out on a phone', (tester) async {
    await show(tester, const Size(360, 780));
    await tester.scrollUntilVisible(find.text('Create an account'), 400,
        scrollable: scrollable());
    expect(find.text('Create an account'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/features/public/presentation/features_page.dart';

/// The Features page used to read "Features — To be implemented".
void main() {
  Future<void> show(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/features', routes: [
      GoRoute(path: '/features', builder: (_, __) => const FeaturesPage()),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
      GoRoute(
          path: '/register', builder: (_, __) => const Text('Register page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('it describes the platform, doctors first', (tester) async {
    await show(tester, const Size(1440, 1000));
    expect(find.textContaining('To be implemented'), findsNothing);
    expect(find.text('Digital prescriptions'), findsOneWidget);
    expect(find.text('Dispensing queue'), findsNothing);
  });

  testWidgets('the switch shows what each audience gets', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.tap(find.text('For Pharmacies'));
    await tester.pumpAndSettle();
    expect(find.text('Dispensing queue'), findsOneWidget);
    expect(find.text('Digital prescriptions'), findsNothing);

    await tester.tap(find.text('For Patients'));
    await tester.pumpAndSettle();
    expect(find.text('Your record, your choice'), findsOneWidget);
  });

  testWidgets('it lays out on a phone', (tester) async {
    await show(tester, const Size(360, 780));
    expect(find.text('Digital prescriptions'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Create an account'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('it leads to signing up', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Create an account'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Register page'), findsOneWidget);
  });
}

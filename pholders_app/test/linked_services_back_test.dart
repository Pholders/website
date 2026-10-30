import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/shared/pages/linked_services_page.dart';

/// The settings pages open Linked Services with go(), which replaces the page
/// instead of stacking it, so its back arrow had nothing to pop and crashed.
void main() {
  Future<GoRouter> show(WidgetTester tester, String start) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font draws every letter as a wide block, so a service tile
    // overflows here though not in a browser. That is not what is under test.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);
    final router = GoRouter(initialLocation: start, routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: AppRoutes.doctorSettings, builder: (_, __) => const Text('Doctor settings')),
          GoRoute(path: AppRoutes.pharmacySettings, builder: (_, __) => const Text('Pharmacy settings')),
          GoRoute(path: AppRoutes.doctorSettingsLinkedServices, builder: (_, __) => const LinkedServicesPage()),
          GoRoute(path: AppRoutes.pharmacySettingsLinkedServices, builder: (_, __) => const LinkedServicesPage()),
        ],
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets("a doctor's back arrow returns to their settings", (tester) async {
    await show(tester, AppRoutes.doctorSettingsLinkedServices);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Doctor settings'), findsOneWidget);
  });

  testWidgets("a pharmacy's back arrow returns to the pharmacy settings", (tester) async {
    await show(tester, AppRoutes.pharmacySettingsLinkedServices);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Pharmacy settings'), findsOneWidget);
  });

  testWidgets('when it was pushed, back still just goes back', (tester) async {
    final router = await show(tester, AppRoutes.pharmacySettings);
    router.push(AppRoutes.doctorSettingsLinkedServices);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Pharmacy settings'), findsOneWidget);
  });
}

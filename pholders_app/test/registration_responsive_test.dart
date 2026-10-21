import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/features/auth/presentation/doctor_register_step2_page.dart';
import 'package:pholders_app/features/auth/presentation/register_page.dart';

void main() {
  for (final viewport in [const Size(320, 568), const Size(1440, 900)]) {
    testWidgets('Practice dropdowns select matching locations at $viewport',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DoctorRegisterStep2Page()),
      );
      await tester.pumpAndSettle();
      final dropdowns = find.byType(DropdownButton<String>);
      final city = dropdowns.at(0);
      final province = dropdowns.at(1);

      await tester.ensureVisible(province);
      await tester.tap(province);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownMenuItem<String>), findsWidgets);
      await tester.tap(find.text('Gauteng').last);
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButton<String>>(province).value, 'Gauteng');

      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      expect(find.text('Cape Town'), findsNothing);
      await tester.tap(find.text('Johannesburg').last);
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButton<String>>(city).value, 'Johannesburg');

      await tester.ensureVisible(province);
      await tester.tap(province);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Western Cape'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Western Cape').last);
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButton<String>>(city).value, isNull);

      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cape Town').last);
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButton<String>>(city).value, 'Cape Town');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Choosing a city first selects its province', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DoctorRegisterStep2Page()),
    );
    await tester.pumpAndSettle();
    final dropdowns = find.byType(DropdownButton<String>);
    await tester.ensureVisible(dropdowns.first);
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cape Town').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(dropdowns.first).value,
        'Cape Town');
    expect(tester.widget<DropdownButton<String>>(dropdowns.last).value,
        'Western Cape');
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 600),
    const Size(1440, 900),
    const Size(2560, 1440),
  ]) {
    testWidgets('Doctor signup stays reachable at $viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final router = GoRouter(
        initialLocation: AppRoutes.register,
        routes: [
          GoRoute(
            path: AppRoutes.register,
            builder: (_, __) => const RegisterPage(),
          ),
          GoRoute(
            path: AppRoutes.registerStep2,
            builder: (_, __) => const DoctorRegisterStep2Page(),
          ),
          GoRoute(
            path: AppRoutes.verifyAccount,
            builder: (_, __) => const Scaffold(body: Text('Verify account')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, 'Test doctor');
      if (viewport.width < 600) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Next').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();

      expect(find.text('Professional Information'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, 'Test clinic');
      if (viewport.width < 600) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Register').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Verify account'), findsOneWidget);
    });
  }
}

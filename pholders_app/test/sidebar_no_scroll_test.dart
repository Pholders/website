import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/shared/widgets/app_sidebar.dart';
import 'package:redux/redux.dart';

/// The doctor's sidebar never scrolls: it fills the window's height, and a
/// window too short for it draws it smaller rather than cutting it off.
void main() {
  Future<List<String>> show(WidgetTester tester, Size window, {bool collapsed = false}) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final errors = <String>[];
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = reportError);

    final store = Store<AppState>(appReducer, initialState: AppState.initial());
    final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
      GoRoute(
        path: '/doctor/dashboard',
        builder: (_, __) => Scaffold(
          body: Row(children: [
            AppSidebar(role: 'doctor', collapsed: collapsed),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ),
    ]);
    await tester.pumpWidget(
        StoreProvider(store: store, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    return errors;
  }

  Finder inSidebar(Finder f) =>
      find.descendant(of: find.byType(AppSidebar), matching: f);

  testWidgets("the doctor's photo is shown whole, not cropped", (tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = Store<AppState>(appReducer, initialState: AppState.initial())
      ..dispatch(const DoctorProfileLoadedAction(
        doctor: Doctor(
          id: 1,
          firstName: 'Sam',
          lastName: 'Smith',
          email: 's@x',
          profileImage: 'https://example.com/sam.jpg',
        ),
      ));
    final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
      GoRoute(
        path: '/doctor/dashboard',
        builder: (_, __) => const Scaffold(
          body: Row(children: [AppSidebar(role: 'doctor', collapsed: false)]),
        ),
      ),
    ]);
    await tester.pumpWidget(
        StoreProvider(store: store, child: MaterialApp.router(routerConfig: router)));

    final photo = tester.widget<Image>(find.byWidgetPredicate(
        (w) => w is Image && w.image is NetworkImage));
    expect(photo.fit, BoxFit.contain);
    expect(photo.alignment, Alignment.bottomCenter);
  });

  for (final (window, collapsed) in [
    (const Size(1440, 1024), false),
    (const Size(1366, 600), false),
    (const Size(1366, 400), false),
    (const Size(900, 400), true),
  ]) {
    testWidgets('fits $window${collapsed ? ' collapsed' : ''} without scrolling',
        (tester) async {
      final errors = await show(tester, window, collapsed: collapsed);

      expect(errors.where((e) => e.contains('overflowed')), isEmpty);
      expect(inSidebar(find.byType(Scrollable)), findsNothing);
      expect(tester.getSize(find.byType(AppSidebar)).height, window.height);
      // Everything is on screen, down to the last thing in it: the log-out
      // bar, or Help & Support when only icons show.
      final last = inSidebar(find.byTooltip(collapsed ? 'Help & Support' : 'Log out'));
      expect(last, findsOneWidget);
      expect(tester.getBottomLeft(last).dy, lessThanOrEqualTo(window.height));
    });
  }
}

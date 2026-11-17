import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/dashboard/presentation/doctor_dashboard_page.dart';
import 'package:pholders_app/shared/utils/greeting.dart';
import 'package:redux/redux.dart';

void main() {
  test('timeOfDayGreeting covers each part of the day', () {
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 0)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 11, 59)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 12)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 16, 59)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 17)), 'Good Evening');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 23, 59)), 'Good Evening');
  });

  test('greetingName gives the doctor the Dr. title once', () {
    expect(greetingName('Thandi Nkosi'), 'Dr. Thandi Nkosi');
    expect(greetingName('  Thandi Nkosi '), 'Dr. Thandi Nkosi');
    expect(greetingName('Dr Thandi Nkosi'), 'Dr. Thandi Nkosi');
    expect(greetingName('dr. Thandi Nkosi'), 'Dr. Thandi Nkosi');
    expect(greetingName('Drew Barry'), 'Dr. Drew Barry', reason: 'a name, not a title');
    expect(greetingName(null), 'Doctor');
    expect(greetingName('  '), 'Doctor');
  });

  testWidgets("the dashboard greets the signed-in doctor by their profile's name",
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The test font draws every letter as a wide block.
      if (!details.toString().contains('overflowed')) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    final store = Store<AppState>(appReducer, initialState: AppState.initial())
      ..dispatch(const LoginSuccessAction(
        token: 't',
        role: 'doctor',
        userName: 'thandi',
        doctor: Doctor(id: 17, firstName: 'Thandi', lastName: 'Nkosi', email: 't@x'),
      ))
      ..dispatch(const AppointmentsLoadedAction(appointments: []));
    final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
      GoRoute(
        path: '/doctor/dashboard',
        builder: (_, __) => Scaffold(
          body: DoctorDashboardPage(clock: () => DateTime(2026, 11, 4, 9)),
        ),
      ),
    ]);
    await tester.pumpWidget(
        StoreProvider(store: store, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning Dr. Thandi Nkosi'), findsOneWidget);
  });
}

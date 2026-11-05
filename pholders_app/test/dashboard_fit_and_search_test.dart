import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/dashboard/data/dashboard_summary.dart';
import 'package:pholders_app/features/doctor/dashboard/presentation/doctor_dashboard_page.dart';
import 'package:pholders_app/features/doctor/patients/data/doctor_patient.dart';
import 'package:pholders_app/shared/widgets/shell_layout.dart';
import 'package:redux/redux.dart';

/// The doctor's shell is drawn on the 1440 × 1024 design frame and scaled to
/// the window, and the dashboard's top-bar search filters its patients table.
final now = DateTime(2026, 11, 4, 9, 15);

Appointment appt(int id, int patientId, String name, {String? reason}) =>
    Appointment(
      id: id,
      patientId: patientId,
      patientName: name,
      date: DateTime(2026, 11, 2),
      timeSlot: '10:00',
      status: 'completed',
      doctorAccepted: true,
      reason: reason,
    );

void main() {
  group('fitScale', () {
    test('the design frame and anything larger are drawn at full size', () {
      expect(ShellLayout.fitScale(const Size(1440, 1024)), 1);
      expect(ShellLayout.fitScale(const Size(2560, 1440)), 1);
    });

    test('a smaller window shrinks by its tighter side', () {
      expect(ShellLayout.fitScale(const Size(1366, 768)), closeTo(0.75, 0.001));
      expect(ShellLayout.fitScale(const Size(1280, 1024)), closeTo(0.889, 0.001));
    });

    test('never below 0.6, so text stays readable', () {
      expect(ShellLayout.fitScale(const Size(1100, 500)), 0.6);
    });
  });

  group('patientMatches', () {
    const patient = DoctorPatient(
      id: 42,
      name: 'Naledi Khumalo',
      visits: 2,
      lastReason: 'Persistent cough',
      email: 'naledi@example.test',
      phone: '0821234567',
      hasCompletedVisit: true,
    );

    test('by name, ID, visit reason, email or phone, ignoring case and order', () {
      expect(patientMatches(patient, ''), isTrue);
      expect(patientMatches(patient, 'naledi'), isTrue);
      expect(patientMatches(patient, '42'), isTrue);
      expect(patientMatches(patient, 'COUGH khumalo'), isTrue);
      expect(patientMatches(patient, 'example.test'), isTrue);
      expect(patientMatches(patient, '082123'), isTrue);
      expect(patientMatches(patient, 'sipho'), isFalse);
    });
  });

  testWidgets(
      "the dashboard's search box filters its patients, and fits a laptop",
      (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The test font draws every letter as a wide block.
      if (!details.toString().contains('overflowed')) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    final store = Store<AppState>(appReducer, initialState: AppState.initial())
      ..dispatch(AppointmentsLoadedAction(appointments: [
        appt(1, 20, 'Naledi Khumalo', reason: 'Cough'),
        appt(2, 21, 'Sipho Dube', reason: 'Back pain'),
      ]));
    final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
      ShellRoute(
        builder: (_, __, child) => ShellLayout(role: 'doctor', child: child),
        routes: [
          GoRoute(
            path: '/doctor/dashboard',
            builder: (_, __) => DoctorDashboardPage(clock: () => now),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(
        StoreProvider(store: store, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    // Laid out on the design frame's height, drawn at the window's.
    final shell = tester.getSize(find.byType(Scaffold).first);
    expect(shell.height, closeTo(1024, 0.5));
    expect(find.byType(FittedBox), findsWidgets);

    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('Sipho Dube'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'back');
    await tester.pumpAndSettle();
    expect(find.text('Sipho Dube'), findsOneWidget);
    expect(find.text('Naledi Khumalo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No patients match "zzz"'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('Sipho Dube'), findsOneWidget);
  });
}

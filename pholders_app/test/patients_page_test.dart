import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_table.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/patients/data/doctor_patient.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/shared/widgets/shell_layout.dart';
import 'package:redux/redux.dart';

/// The Patients page, laid out to the design, shows what the appointments
/// say: its tabs filter by that, the top bar's search narrows it, and a row
/// opens the patient. Nothing on it is invented.
final now = DateTime(2026, 11, 4, 9);

Appointment appt(
  int id,
  int patientId,
  String name,
  DateTime date, {
  String status = 'completed',
  bool accepted = true,
  String? reason,
  String? email,
}) =>
    Appointment(
      id: id,
      patientId: patientId,
      patientName: name,
      date: date,
      timeSlot: '10:00',
      status: status,
      doctorAccepted: accepted,
      reason: reason,
      patientEmail: email,
    );

void main() {
  late List<DoctorPatient> opened;

  Future<void> show(WidgetTester tester) async {
    // Wide enough that the test font's block letters leave the alert bar room.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The test font draws every letter as a wide block.
      if (!details.toString().contains('overflowed'))
        reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    opened = [];
    final store = Store<AppState>(appReducer, initialState: AppState.initial())
      ..dispatch(AppointmentsLoadedAction(appointments: [
        appt(1, 20, 'Naledi Khumalo', DateTime(2026, 10, 30),
            reason: 'Cough', email: 'naledi@example.test'),
        appt(2, 21, 'Sipho Dube', DateTime(2026, 10, 1), reason: 'Back pain'),
        appt(3, 21, 'Sipho Dube', DateTime(2026, 11, 12), status: 'scheduled'),
        appt(4, 22, 'Lerato Molefe', DateTime(2026, 11, 20),
            status: 'scheduled', accepted: false),
      ]));
    final router = GoRouter(initialLocation: '/doctor/patients', routes: [
      ShellRoute(
        builder: (_, __, child) => ShellLayout(role: 'doctor', child: child),
        routes: [
          GoRoute(
            path: '/doctor/patients',
            builder: (_, __) => Scaffold(
              body: PatientsScreen(onPatientTap: opened.add, clock: () => now),
            ),
          ),
          GoRoute(
            path: '/doctor/appointments',
            builder: (_, __) => const Text('Appointments page'),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(StoreProvider(
        store: store, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
  }

  testWidgets('lists everyone with real statuses, and nothing invented',
      (tester) async {
    await show(tester);

    expect(find.text('Total: 3'), findsOneWidget);
    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('Sipho Dube'), findsOneWidget);
    expect(find.text('Lerato Molefe'), findsOneWidget);
    expect(find.text('Upcoming visit'), findsWidgets);
    expect(find.text('1 booking is waiting for you to accept'), findsOneWidget);

    for (final made in ['Maria Wilson', 'Stable', 'Monitored', 'High', 'Low']) {
      expect(find.text(made), findsNothing, reason: '$made is not recorded');
    }
    expect(find.byTooltip('Delete patient'), findsNothing);
  });

  testWidgets('a tab shows only the patients in that state', (tester) async {
    await show(tester);

    await tester.tap(find.text('Awaiting acceptance').first);
    await tester.pumpAndSettle();
    expect(find.text('Lerato Molefe'), findsOneWidget);
    expect(find.text('Sipho Dube'), findsNothing);
    expect(find.text('Naledi Khumalo'), findsNothing);

    await tester.tap(find.text('Visit today'));
    await tester.pumpAndSettle();
    expect(find.text('No patients under Visit today'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Naledi Khumalo'), findsOneWidget);
  });

  testWidgets("the top bar's search narrows the list", (tester) async {
    await show(tester);

    await tester.enterText(find.byType(TextField), 'back pain');
    await tester.pumpAndSettle();
    expect(find.text('Sipho Dube'), findsOneWidget);
    expect(find.text('Naledi Khumalo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nobody matches "zzz"'), findsOneWidget);
  });

  testWidgets('a row and its three dots open the actions, not the profile',
      (tester) async {
    await show(tester);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    // Clicking the row opens the menu; the profile is only one choice in it.
    await tester.tap(find.text('Naledi Khumalo'));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    for (final label in [
      'View Patient Profile',
      'Create Prescription',
      'Send Medication Reminder',
      'Send Safety Alert',
      'Notify Prescription Ready',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('View Patient Profile'), findsNothing);
    expect(opened, isEmpty);

    await tester.tap(find.byTooltip('More actions').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Patient Profile'));
    await tester.pumpAndSettle();
    expect(opened.map((p) => p.name), ['Sipho Dube']);
  });

  testWidgets('the messages with no backend yet cannot be chosen',
      (tester) async {
    await show(tester);

    await tester.tap(find.text('Naledi Khumalo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Safety Alert'));
    await tester.pumpAndSettle();
    // Nothing happened: the menu is still open and nothing was opened.
    expect(find.text('Send Safety Alert'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets("Create Prescription offers only that patient's consultations",
      (tester) async {
    await show(tester);

    await tester.tap(find.text('Naledi Khumalo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Prescription'));
    await tester.pumpAndSettle();
    expect(find.text('New Prescription'), findsOneWidget);
    // Naledi has one consultation, so it is already chosen.
    expect(find.textContaining('Naledi Khumalo —'), findsOneWidget);
    expect(find.textContaining('Sipho Dube —'), findsNothing);
  });

  testWidgets('the alert opens Appointments, where accepting happens',
      (tester) async {
    await show(tester);

    await tester.tap(find.text('1 booking is waiting for you to accept'));
    await tester.pumpAndSettle();
    expect(find.text('Appointments page'), findsOneWidget);
  });

  testWidgets('the table has an always-visible scrollbar', (tester) async {
    await show(tester);
    final bar = tester.widget<RawScrollbar>(find.descendant(
        of: find.byType(PatientTableList),
        matching: find.byType(RawScrollbar)));
    expect(bar.thumbVisibility, isTrue);
    expect(bar.trackVisibility, isTrue);
  });
}

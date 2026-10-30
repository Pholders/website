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
import 'package:redux/redux.dart';

/// The dashboard is worked out from the doctor's own appointments. It used to
/// show four "Maria Wilson" appointments on 14 March, "72 appointments,
/// +12%", an alert about a made-up patient and an invented patient table.
final now = DateTime(2026, 10, 30, 9, 15); // a Friday

Appointment appt(
  int id,
  int patientId,
  String name,
  DateTime date, {
  String slot = '10:00',
  String status = 'scheduled',
  bool accepted = true,
  String? reason,
}) =>
    Appointment(
      id: id,
      patientId: patientId,
      patientName: name,
      date: date,
      timeSlot: slot,
      status: status,
      doctorAccepted: accepted,
      reason: reason,
    );

final appointments = [
  // today
  appt(1, 20, 'Naledi Khumalo', DateTime(2026, 10, 30), slot: '14:00', reason: 'Cough'),
  appt(2, 21, 'Sipho Dube', DateTime(2026, 10, 30), slot: '09:30', accepted: false),
  appt(3, 22, 'Ayanda Zulu', DateTime(2026, 10, 30), slot: '11:00', status: 'cancelled'),
  // earlier this month and last month
  appt(4, 20, 'Naledi Khumalo', DateTime(2026, 10, 2), status: 'completed', reason: 'Flu'),
  appt(5, 23, 'Lerato Molefe', DateTime(2026, 9, 15), status: 'completed'),
  appt(6, 23, 'Lerato Molefe', DateTime(2026, 9, 20), status: 'completed'),
  // ahead
  appt(7, 23, 'Lerato Molefe', DateTime(2026, 11, 4), slot: '08:00', accepted: false),
];

void main() {
  group('the numbers', () {
    test("today's appointments leave out cancelled ones and run earliest first", () {
      expect(todaysAppointments(appointments, now).map((a) => a.id), [2, 1]);
    });

    test('bookings waiting to be accepted are paid, unaccepted and not past', () {
      expect(awaitingAcceptance(appointments, now), 2);
      expect(
        awaitingAcceptance(
            [appt(9, 30, 'Old', DateTime(2026, 10, 1), accepted: false)], now),
        0,
        reason: 'a past booking can no longer be accepted',
      );
      expect(
        awaitingAcceptance(
            [appt(9, 30, 'Unpaid', DateTime(2026, 11, 1), accepted: false, status: 'pending_payment')],
            now),
        0,
        reason: 'the doctor accepts only after payment',
      );
    });

    test('this month against last month', () {
      expect(appointmentsInMonth(appointments, now), 3);
      expect(changeVersusLastMonth(appointments, now), '+50%');
      expect(changeVersusLastMonth([appointments.first], now), isNull,
          reason: 'no appointments last month, so no percentage');
    });

    test('new patients are the ones whose first booking is this month', () {
      // Ayanda's only booking was cancelled, but she did book, and the
    // Patients page lists her too.
    expect(newPatientsThisMonth(appointments, now), 3);
    });

    test('last visit is the latest on or before today', () {
      expect(lastVisit(appointments, 23, now), DateTime(2026, 9, 20));
      expect(lastVisit(appointments, 20, now), DateTime(2026, 10, 30));
    });

    test('the next appointment after today', () {
      expect(nextAppointmentAfterToday(appointments, now)?.id, 7);
    });

    test('the monthly trend counts appointments and distinct patients', () {
      final months = activityTrend(appointments, TrendPeriod.monthly, now);
      expect(months, hasLength(12));
      expect(months.last.label, 'Oct');
      expect((months.last.appointments, months.last.patients), (3, 2));
      expect(months[months.length - 2].label, 'Sep');
      expect((months[months.length - 2].appointments, months[months.length - 2].patients), (2, 1));
      expect(activityTrend(appointments, TrendPeriod.weekly, now).last.label, 'Fri');
      expect(activityTrend(appointments, TrendPeriod.yearly, now).map((b) => b.label),
          ['2022', '2023', '2024', '2025', '2026']);
    });
  });

  group('the page', () {
    Future<void> show(WidgetTester tester, List<Appointment> list) async {
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
        ..dispatch(AppointmentsLoadedAction(appointments: list));
      final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
        GoRoute(
          path: '/doctor/dashboard',
          builder: (_, __) => Scaffold(body: DoctorDashboardPage(clock: () => now)),
        ),
        GoRoute(path: '/doctor/appointments', builder: (_, __) => const Text('Appointments page')),
        GoRoute(path: '/doctor/patients', builder: (_, __) => const Text('Patients page')),
        GoRoute(
          path: '/doctor/patients/:id',
          builder: (_, state) => Text('Patient ${state.pathParameters['id']}'),
        ),
      ]);
      await tester.pumpWidget(
          StoreProvider(store: store, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
    }

    testWidgets("shows today's real date, appointments and totals", (tester) async {
      await show(tester, appointments);

      expect(find.text('Friday, 30th October'), findsOneWidget);
      expect(find.text('Sipho Dube'), findsWidgets);
      expect(find.text('Naledi Khumalo'), findsWidgets);
      expect(find.text('2 bookings are waiting for you to accept'), findsOneWidget);
      expect(find.text('+50%'), findsOneWidget);
      expect(find.text('Lerato Molefe'), findsOneWidget, reason: 'in recent patients');

      expect(find.text('Maria Wilson'), findsNothing);
      expect(find.text('72'), findsNothing);
      expect(find.textContaining('Prince Mashumu'), findsNothing);
      expect(find.text('Attention Needed'), findsNothing);
      expect(find.byTooltip('Delete patient'), findsNothing);
    });

    testWidgets('the waiting-bookings alert opens Appointments', (tester) async {
      await show(tester, appointments);
      await tester.tap(find.text('2 bookings are waiting for you to accept'));
      await tester.pumpAndSettle();
      expect(find.text('Appointments page'), findsOneWidget);
    });

    testWidgets("a recent patient's row opens their record", (tester) async {
      await show(tester, appointments);
      await tester.tap(find.text('Lerato Molefe'));
      await tester.pumpAndSettle();
      expect(find.text('Patient 23'), findsOneWidget);
    });

    testWidgets('the upcoming filter keeps only patients with a visit ahead', (tester) async {
      await show(tester, appointments);
      await tester.tap(find.text('With an upcoming visit'));
      await tester.pumpAndSettle();
      expect(find.text('Lerato Molefe'), findsOneWidget);
      expect(find.text('Ayanda Zulu'), findsNothing);
    });

    testWidgets('an empty day says so and names the next appointment', (tester) async {
      await show(tester, [appointments.last]);
      expect(find.textContaining('No appointments today.'), findsOneWidget);
      expect(find.textContaining('Next: Lerato Molefe'), findsOneWidget);
    });

    testWidgets('a new doctor sees no invented patients', (tester) async {
      await show(tester, const []);
      expect(find.text('Patients appear here once they book with you'), findsOneWidget);
      expect(find.textContaining('waiting for you to accept'), findsNothing);
    });
  });
}

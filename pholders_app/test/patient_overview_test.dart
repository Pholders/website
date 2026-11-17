import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_state.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_overview.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:redux/redux.dart';

/// The "Patient profile" tab, laid out to the design, shows only what is
/// recorded: this patient's visits with the doctor, their latest vitals as
/// taken, their active medication, and their record's timeline.
final now = DateTime(2026, 11, 4, 9);

final patient = Patient(
  id: '20',
  name: 'Naledi Khumalo',
  condition: 'Cough',
  lastActivity: '30 Oct 2026',
  status: PatientStatus.stable,
  priority: 'Not set',
  category: PatientCategory.outpatient,
  email: 'naledi@example.test',
  phone: '082 000 0000',
);

Appointment appt(int id, int patientId, DateTime date,
        {String status = 'completed', String? reason}) =>
    Appointment(
      id: id,
      patientId: patientId,
      patientName: 'Someone',
      date: date,
      timeSlot: '11:00',
      status: status,
      doctorAccepted: true,
      reason: reason,
    );

class FakeRecords implements PatientRecordRepository {
  FakeRecords(
      {this.vitals = const [], this.history = const [], this.failHistory});
  final List<PatientVital> vitals;
  final List<PatientHistoryEntry> history;
  final String? failHistory;

  @override
  Future<List<PatientVital>> fetchVitals(String id, {int limit = 50}) async =>
      vitals;
  @override
  Future<List<PatientHistoryEntry>> fetchHistory(String id) async {
    if (failHistory != null) {
      throw ApiException(message: failHistory!, statusCode: 403);
    }
    return history;
  }

  @override
  Future<List<PatientMedication>> fetchMedications(String id) async => const [
        PatientMedication(
            name: 'Metformin', dosage: '500 mg', frequency: 'Twice daily'),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> show(WidgetTester tester, FakeRecords repo,
    {double? height}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    // The test font draws every letter as a wide block.
    if (!details.toString().contains('overflowed')) reportError?.call(details);
  };
  addTearDown(() => FlutterError.onError = reportError);

  final base = AppState.initial();
  final store = Store<AppState>(
    (s, _) => s,
    initialState: AppState(
      authState: base.authState,
      appointmentsState: AppointmentsState(hasLoadedOnce: true, appointments: [
        appt(1, 20, DateTime(2026, 10, 30), reason: 'Cough'),
        appt(2, 20, DateTime(2026, 11, 12),
            status: 'scheduled', reason: 'Follow-up'),
        appt(3, 99, DateTime(2026, 11, 13),
            status: 'scheduled', reason: 'Not theirs'),
      ]),
      prescriptionsState: base.prescriptionsState,
      reviewsState: base.reviewsState,
      dispensingState: base.dispensingState,
      pharmacyOrdersState: base.pharmacyOrdersState,
    ),
  );
  await tester.pumpWidget(StoreProvider<AppState>(
    store: store,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PatientOverview(
              patient: patient,
              repository: repo,
              clock: () => now,
              height: height),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the card shows who they are and what the bookings say',
      (tester) async {
    await show(tester, FakeRecords());

    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('naledi@example.test'), findsOneWidget);
    expect(find.text('082 000 0000'), findsOneWidget);
    expect(find.text('Upcoming visit'), findsOneWidget);
    expect(find.text('30/10/2026'), findsWidgets); // patient since, last visit
    expect(find.text('12/11/2026'), findsOneWidget); // next visit
    // Nothing the record does not hold.
    for (final made in ['Gender', 'Blood', 'Bed No.', 'Cardiology', 'Edit']) {
      expect(find.text(made), findsNothing, reason: '$made is not recorded');
    }
  });

  testWidgets('vitals are the latest taken, with no verdict on them',
      (tester) async {
    await show(
        tester,
        FakeRecords(vitals: [
          PatientVital(
              measuredAt: DateTime(2026, 10, 30),
              systolicBp: 128,
              diastolicBp: 82,
              heartRate: 71),
          PatientVital(measuredAt: DateTime(2026, 9, 1), weightKg: 74),
        ]));

    expect(find.text('128/82 mmHg'), findsOneWidget);
    expect(find.text('71 bpm'), findsOneWidget);
    expect(find.text('74 kg'), findsOneWidget);
    expect(find.text('Taken 01/09/2026'), findsOneWidget);
    expect(find.text('Not recorded'), findsOneWidget); // glucose
    expect(find.textContaining('norm'), findsNothing);
  });

  testWidgets("visits are this patient's, split future and past",
      (tester) async {
    await show(tester, FakeRecords());

    expect(find.text('Future visits (1)'), findsOneWidget);
    expect(find.text('Follow-up'), findsOneWidget);
    expect(find.text('Not theirs'), findsNothing);

    await tester.tap(find.text('Past Visits (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Cough'), findsWidgets);
    expect(find.text('Follow-up'), findsNothing);

    await tester.tap(find.text('Planned Treatments (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Metformin'), findsOneWidget);
    expect(find.text('500 mg · Twice daily'), findsOneWidget);
  });

  testWidgets('the timeline is their record, or says why it is not shown',
      (tester) async {
    await show(
        tester,
        FakeRecords(history: [
          PatientHistoryEntry(
              kind: 'prescription',
              date: DateTime(2026, 10, 30),
              notes: 'Upper respiratory infection',
              providerName: 'Thandi Nkosi'),
        ]));
    expect(find.text('Upper respiratory infection'), findsOneWidget);
    expect(find.text('Prescription · Dr Thandi Nkosi'), findsOneWidget);
  });

  testWidgets('a record the doctor may not read says why', (tester) async {
    await show(tester, FakeRecords(failHistory: 'Not your patient'));
    expect(find.text('Not your patient'), findsOneWidget);
  });

  testWidgets('given a height, the panels stretch to fill it', (tester) async {
    await show(tester, FakeRecords(), height: 900);

    // The white card holding [text]: its nearest white, rounded container.
    Rect panel(String text) => tester.getRect(find
        .ancestor(
          of: find.text(text),
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.white &&
              (w.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(28)),
        )
        .first);
    final overview = tester.getRect(find.byType(PatientOverview));
    expect(overview.height, 900);
    // Both panels end at the overview's bottom padding.
    expect(panel('Timeline').bottom, closeTo(overview.bottom - 26, 1));
    expect(panel('Future visits (1)').bottom, closeTo(overview.bottom - 26, 1));
  });
}

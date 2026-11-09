import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_state.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart'
    as api;
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_state.dart';
import 'package:redux/redux.dart';

/// A patient's profile tabs used to show invented clinical data under the
/// real patient's name: Isotretinoin scripts, Amoxicillin courses, a medical
/// history of heart disease and liposuction, and visits with "Dr Sam Smith".
/// Each tab now shows only that patient's real data, or says there is none.
final patient = Patient(
  id: '17',
  name: 'Pule Test',
  condition: 'Checkup',
  lastActivity: '29 Oct 2026',
  status: PatientStatus.stable,
  priority: 'Not set',
  category: PatientCategory.outpatient,
);

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.status, this.body);
  final int status;
  final Object body;

  @override
  Future<ResponseBody> fetch(
          RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });

  @override
  void close({bool force = false}) {}
}

PatientRecordRepository repo(int status, Object body) =>
    PatientRecordRepository(ApiClient(
        tokenStorage: const _NoSession(),
        dio: Dio()..httpClientAdapter = _Server(status, body)));

String day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime.utc(d.year, d.month, d.day).toIso8601String();
}

Store<AppState> store({
  List<Appointment> appointments = const [],
  List<api.Prescription> prescriptions = const [],
}) {
  final base = AppState.initial();
  return Store<AppState>(
    (s, _) => s,
    initialState: AppState(
      authState: base.authState,
      appointmentsState:
          AppointmentsState(appointments: appointments, hasLoadedOnce: true),
      prescriptionsState:
          PrescriptionsState(prescriptions: prescriptions, hasLoadedOnce: true),
      reviewsState: base.reviewsState,
      dispensingState: base.dispensingState,
      pharmacyOrdersState: base.pharmacyOrdersState,
    ),
  );
}

Future<void> show(WidgetTester tester, Store<AppState> s, Widget child) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(StoreProvider<AppState>(
    store: s,
    child:
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Appointments tab', () {
    Appointment visit(
            int id, int patientId, String date, String reason, String status) =>
        Appointment.fromJson({
          'id': id,
          'patientId': patientId,
          'patientName': 'P$patientId',
          'appointmentDate': date,
          'timeSlot': '09:00',
          'reason': reason,
          'status': status,
        });

    testWidgets("shows only this patient's visits, split upcoming and past",
        (tester) async {
      await show(
        tester,
        store(appointments: [
          visit(1, 17, day(0), 'Follow-up', 'scheduled'),
          visit(2, 17, day(0), 'First visit', 'completed'),
          visit(3, 99, day(0), 'Someone else', 'scheduled'),
        ]),
        AppointmentsScreen(patient: patient),
      );

      expect(find.text('Future visits (1)'), findsOneWidget);
      expect(find.text('Past Visits (1)'), findsOneWidget);
      // The day view opens on the next visit's day, the visit in its hour.
      expect(find.text('9 am'), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('Someone else'), findsNothing);
      expect(find.text('Treatment of diabetes'), findsNothing);
      expect(find.text('Dr Sam Smith'), findsNothing);

      await tester.tap(find.text('Past Visits (1)'));
      await tester.pumpAndSettle();
      expect(find.text('First visit'), findsOneWidget);
    });

    testWidgets('the arrows move the day, and Week lists the days',
        (tester) async {
      await show(
        tester,
        store(appointments: [visit(1, 17, day(1), 'Follow-up', 'scheduled')]),
        AppointmentsScreen(patient: patient),
      );
      expect(find.text('Follow-up'), findsOneWidget);

      // The day after has nothing booked.
      await tester.tap(find.byTooltip('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Follow-up'), findsNothing);

      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('No visits'), findsWidgets);
    });

    testWidgets('a patient with no visits is told so', (tester) async {
      await show(tester, store(), AppointmentsScreen(patient: patient));
      expect(find.text('No upcoming visits with you.'), findsOneWidget);
    });
  });

  group('Prescriptions tab', () {
    api.Prescription rx(int id, int patientId, String diagnosis) =>
        api.Prescription.fromJson({
          'id': id,
          'prescriptionNumber': 'RX-$id',
          'patient': 'P$patientId',
          'patientId': patientId,
          'diagnosis': diagnosis,
          'status': 'signed',
          'createdAt': '2026-10-29T08:00:00Z',
        });

    testWidgets("shows only this patient's real prescriptions", (tester) async {
      await show(
        tester,
        store(prescriptions: [
          rx(1, 17, 'Hypertension'),
          rx(2, 99, 'Someone else')
        ]),
        PrescriptionsScreen(patient: patient),
      );
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('Someone else'), findsNothing);
      expect(find.text('Isotretinoin'), findsNothing);
    });

    testWidgets('a row opens its details in place, with nothing invented',
        (tester) async {
      await show(tester, store(prescriptions: [rx(1, 17, 'Hypertension')]),
          PrescriptionsScreen(patient: patient));
      await tester.tap(find.text('Hypertension'));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Date Issued'), findsNothing); // the table is gone
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('RX-1'), findsOneWidget);
      expect(find.text('29 Oct 2026'), findsOneWidget);
      // It used to add "once daily" and "30 days" to every prescription.
      expect(find.textContaining('once daily'), findsNothing);
      expect(find.text('30 days'), findsNothing);

      await tester.tap(find.text('Back to prescriptions'));
      await tester.pumpAndSettle();
      expect(find.text('Date Issued'), findsOneWidget);
    });

    testWidgets('given a height, only the rows scroll, under the header',
        (tester) async {
      await show(
        tester,
        store(prescriptions: [
          for (var i = 1; i <= 25; i++) rx(i, 17, 'Diagnosis $i'),
        ]),
        SizedBox(height: 600, child: PrescriptionsScreen(patient: patient)),
      );
      expect(find.text('Diagnosis 1'), findsOneWidget);
      expect(find.text('Diagnosis 25'), findsNothing);
      final headerTop = tester.getTopLeft(find.text('Date Issued')).dy;

      await tester.drag(find.text('Diagnosis 1'), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Diagnosis 25'), findsOneWidget);
      // The header and filters stayed where they were.
      expect(tester.getTopLeft(find.text('Date Issued')).dy, headerTop);
      expect(find.text('Prescriptions'), findsOneWidget);
    });

    testWidgets(
        'no edit or delete is offered; revoke has its own icon',
        (tester) async {
      await show(tester, store(prescriptions: [rx(1, 17, 'Hypertension')]),
          PrescriptionsScreen(patient: patient));
      // They once only changed the list on screen. A written prescription
      // cannot be edited and nothing is deleted, so neither is shown.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Revoke stops this signed prescription, after asking why.
      await tester.tap(find.byIcon(Icons.block));
      await tester.pumpAndSettle();
      expect(find.text('Revoke this prescription?'), findsOneWidget);
    });
  });

  group('Medication tab', () {
    testWidgets("shows the patient's current medication from their record",
        (tester) async {
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          repository: repo(200, {
            'success': true,
            'data': [
              {
                'medication_name': 'Amlodipine',
                'dosage': '5mg',
                'frequency': 'Once daily',
                'start_date': '2026-10-01',
                'prescribed_by': 'Dr Pule Doctor',
              },
            ],
          }),
        ),
      );
      // Name and strength on top, how it is taken in the Dosage pill.
      expect(find.text('Amlodipine 5mg'), findsOneWidget);
      expect(find.text('Once daily'), findsWidgets);
      expect(find.text('Ongoing'), findsWidgets);
      expect(
          find.textContaining('Prescribed by Dr Pule Doctor'), findsOneWidget);
      expect(find.text('Isotretinoin'), findsNothing);
      expect(find.textContaining('Liposuction'), findsNothing);
    });

    testWidgets('no medication on record says so', (tester) async {
      await show(
          tester,
          store(),
          MedicationScreen(
              patient: patient,
              repository: repo(200, {'success': true, 'data': []})));
      expect(find.textContaining('No current medication'), findsOneWidget);
    });

    testWidgets("a doctor the patient never booked sees the server's reason",
        (tester) async {
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          repository: repo(403, {
            'success': false,
            'message':
                'You can see the record only of patients who have booked with you',
          }),
        ),
      );
      // Both the medications and the medical history say so.
      expect(
          find.text(
              'You can see the record only of patients who have booked with you'),
          findsWidgets);
    });

    Map<String, Object?> med(String name, String start, [String? end]) => {
          'medication_name': name,
          'dosage': '20mg',
          'frequency': 'Once daily',
          'start_date': start,
          'end_date': end,
        };

    testWidgets(
        'the history lists each medication, with how long and whether it is '
        'still taken', (tester) async {
      final now = DateTime.now();
      String on(DateTime d) => DateTime.utc(d.year, d.month, d.day)
          .toIso8601String()
          .substring(0, 10);
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          repository: repo(200, {
            'success': true,
            'data': [
              med('Isotretinoin', on(now.subtract(const Duration(days: 60))),
                  on(now.subtract(const Duration(days: 30)))),
              med('Amlodipine', on(now.subtract(const Duration(days: 5))),
                  on(now.add(const Duration(days: 25)))),
            ],
          }),
        ),
      );
      expect(find.text('Medication history'), findsOneWidget);
      for (final column in [
        'Medication',
        'Dosage',
        'Frequency',
        'Duration',
        'Status'
      ]) {
        expect(find.text(column), findsWidgets);
      }
      expect(find.text('30 days'), findsNWidgets(2));
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Stopped'), findsOneWidget);
      // Still being taken comes first.
      expect(tester.getTopLeft(find.text('Amlodipine')).dy,
          lessThan(tester.getTopLeft(find.text('Isotretinoin')).dy));

      await tester.enterText(find.byType(TextField), 'iso');
      await tester.pump();
      expect(find.text('Amlodipine'), findsNothing);
      expect(find.text('Isotretinoin'), findsOneWidget);

      expect(find.text('Prescribe Medication'), findsOneWidget);
    });

    testWidgets("a row's actions show what the record holds on it",
        (tester) async {
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          repository: repo(200, {
            'success': true,
            'data': [
              {
                ...med('Amlodipine', '2026-10-01'),
                'reason': 'High blood pressure',
              },
            ],
          }),
        ),
      );
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      for (final soon in [
        'Adjust Medication',
        'Stop Medication',
        'Send Reminder'
      ]) {
        expect(find.text(soon), findsOneWidget);
      }
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();
      // The tab becomes the medication's details, from the record.
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Medications'), findsNothing);
      expect(find.text('Amlodipine'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('High blood pressure'), findsOneWidget);
      expect(find.text('Adherence'), findsNothing);

      await tester.tap(find.text('Back to medications'));
      await tester.pumpAndSettle();
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Details'), findsNothing);

      // A click on the medication's card opens the same details.
      await tester.tap(find.text('Amlodipine 20mg'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('High blood pressure'), findsOneWidget);
    });

    testWidgets('given a height, the history scrolls inside its card',
        (tester) async {
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          height: 700,
          repository: repo(200, {
            'success': true,
            'data': [
              for (var i = 1; i <= 20; i++)
                med('Medicine $i', '2026-01-${i.toString().padLeft(2, '0')}'),
            ],
          }),
        ),
      );
      // The tab keeps its height however many rows there are.
      expect(tester.getSize(find.byType(MedicationScreen)).height, 700);
      // The newest rows show; the oldest wait below, inside the card.
      expect(find.text('Medicine 20'), findsOneWidget);
      expect(find.text('Medicine 1'), findsNothing);

      await tester.drag(find.text('Medicine 20'), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('Medicine 1'), findsOneWidget);
      expect(find.text('Medications'), findsOneWidget); // still on screen
    });

    testWidgets('nothing invented: no adherence or condition categories',
        (tester) async {
      await show(
          tester,
          store(),
          MedicationScreen(
              patient: patient,
              repository: repo(200, {'success': true, 'data': []})));
      for (final made in [
        'Adherence',
        'Critical',
        'Chronic disease',
        'Surgery'
      ]) {
        expect(find.text(made), findsNothing, reason: '$made is not recorded');
      }
    });
  });

  group('History tab', () {
    testWidgets("shows the patient's real visits and prescriptions",
        (tester) async {
      await show(
        tester,
        store(),
        MedicalHistoryScreen(
          patient: patient,
          repository: repo(200, {
            'success': true,
            'data': [
              {
                'record_type': 'prescription',
                'appointment_date': '2026-10-29',
                'status': 'signed',
                'provider_name': 'Pule Doctor',
                'specialization': 'General Practitioner',
                'notes': 'Hypertension',
              },
              {
                'record_type': 'appointment',
                'appointment_date': '2026-10-20',
                'status': 'completed',
                'provider_name': 'Thandi Nkosi',
              },
            ],
          }),
        ),
      );
      expect(find.text('Prescription issued'), findsOneWidget);
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('Visit completed'), findsOneWidget);
      // Newest first, each day under its date.
      expect(find.text('Thursday, 29 Oct 2026'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Prescription issued')).dy,
          lessThan(tester.getTopLeft(find.text('Visit completed')).dy));
      // No note can be kept on the server yet, so none is offered.
      expect(find.textContaining('Add note'), findsNothing);

      // View opens what the record holds on it.
      await tester.tap(find.text('View').first);
      await tester.pumpAndSettle();
      expect(find.text('Dr Pule Doctor'), findsOneWidget);
      expect(find.text('General Practitioner'), findsOneWidget);

      // Filters keep one kind.
      await tester.tap(find.text('Visits'));
      await tester.pumpAndSettle();
      expect(find.text('Prescription issued'), findsNothing);
      expect(find.text('Visit completed'), findsOneWidget);
    });

    testWidgets('an empty history says so', (tester) async {
      await show(
          tester,
          store(),
          MedicalHistoryScreen(
              patient: patient,
              repository: repo(200, {'success': true, 'data': []})));
      expect(find.textContaining('No completed visits or prescriptions'),
          findsOneWidget);
    });
  });

  group('Documents tab', () {
    testWidgets("lists the patient's stored files with a download each",
        (tester) async {
      await show(
        tester,
        store(),
        DocumentsScreen(
          patient: patient,
          repository: repo(200, {
            'success': true,
            'data': [
              {
                'id': 5,
                'file_name': 'blood-results.pdf',
                'file_type': 'application/pdf',
                'file_size': 204800,
                'category': 'lab_results',
                'upload_timestamp': '2026-10-28T10:00:00Z',
              },
            ],
          }),
        ),
      );
      expect(find.text('blood-results.pdf'), findsOneWidget);
      expect(find.textContaining('lab results · 200 KB'), findsOneWidget);
      expect(find.byTooltip('Download'), findsOneWidget);
      expect(find.text('Blood Test Report'), findsNothing);
    });

    testWidgets('no stored documents says so', (tester) async {
      await show(
          tester,
          store(),
          DocumentsScreen(
              patient: patient,
              repository: repo(200, {'success': true, 'data': []})));
      expect(
          find.textContaining('has not stored any documents'), findsOneWidget);
    });
  });
}

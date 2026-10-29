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
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async =>
      ResponseBody.fromString(jsonEncode(body), status,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  void close({bool force = false}) {}
}

PatientRecordRepository repo(int status, Object body) => PatientRecordRepository(
    ApiClient(tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = _Server(status, body)));

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
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Appointments tab', () {
    Appointment visit(int id, int patientId, String date, String reason, String status) =>
        Appointment.fromJson({
          'id': id,
          'patientId': patientId,
          'patientName': 'P$patientId',
          'appointmentDate': date,
          'timeSlot': '09:00',
          'reason': reason,
          'status': status,
        });

    testWidgets("shows only this patient's visits, split upcoming and past", (tester) async {
      await show(
        tester,
        store(appointments: [
          visit(1, 17, day(0), 'Follow-up', 'scheduled'),
          visit(2, 17, day(0), 'First visit', 'completed'),
          visit(3, 99, day(0), 'Someone else', 'scheduled'),
        ]),
        AppointmentsScreen(patient: patient),
      );

      expect(find.text('Upcoming (1)'), findsOneWidget);
      expect(find.text('Past (1)'), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('Someone else'), findsNothing);
      expect(find.text('Treatment of diabetes'), findsNothing);

      await tester.tap(find.text('Past (1)'));
      await tester.pumpAndSettle();
      expect(find.text('First visit'), findsOneWidget);
    });

    testWidgets('a patient with no visits is told so', (tester) async {
      await show(tester, store(), AppointmentsScreen(patient: patient));
      expect(find.text('No upcoming visits with you.'), findsOneWidget);
    });
  });

  group('Prescriptions tab', () {
    api.Prescription rx(int id, int patientId, String diagnosis) => api.Prescription.fromJson({
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
        store(prescriptions: [rx(1, 17, 'Hypertension'), rx(2, 99, 'Someone else')]),
        PrescriptionsScreen(patient: patient),
      );
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('Someone else'), findsNothing);
      expect(find.text('Isotretinoin'), findsNothing);
    });

    testWidgets('edit and delete, which only changed the list on screen, are gone',
        (tester) async {
      await show(tester, store(prescriptions: [rx(1, 17, 'Hypertension')]),
          PrescriptionsScreen(patient: patient));
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  group('Medication tab', () {
    testWidgets("shows the patient's current medication from their record", (tester) async {
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
      expect(find.text('Amlodipine'), findsOneWidget);
      expect(find.text('5mg · Once daily'), findsOneWidget);
      expect(find.textContaining('Prescribed by Dr Pule Doctor'), findsOneWidget);
      expect(find.text('Isotretinoin'), findsNothing);
      expect(find.textContaining('Liposuction'), findsNothing);
    });

    testWidgets('no medication on record says so', (tester) async {
      await show(tester, store(),
          MedicationScreen(patient: patient, repository: repo(200, {'success': true, 'data': []})));
      expect(find.textContaining('No current medication'), findsOneWidget);
    });

    testWidgets("a doctor the patient never booked sees the server's reason", (tester) async {
      await show(
        tester,
        store(),
        MedicationScreen(
          patient: patient,
          repository: repo(403, {
            'success': false,
            'message': 'You can see the record only of patients who have booked with you',
          }),
        ),
      );
      expect(find.text('You can see the record only of patients who have booked with you'),
          findsOneWidget);
    });
  });

  group('History tab', () {
    testWidgets("shows the patient's real visits and prescriptions", (tester) async {
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
      expect(find.text('Prescription'), findsOneWidget);
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('Dr Pule Doctor · General Practitioner'), findsOneWidget);
      expect(find.text('Visit'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      // No note can be kept on the server yet, so none is offered.
      expect(find.textContaining('Add note'), findsNothing);
    });

    testWidgets('an empty history says so', (tester) async {
      await show(tester, store(),
          MedicalHistoryScreen(patient: patient, repository: repo(200, {'success': true, 'data': []})));
      expect(find.textContaining('No completed visits or prescriptions'), findsOneWidget);
    });
  });

  group('Documents tab', () {
    testWidgets("lists the patient's stored files with a download each", (tester) async {
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
      await show(tester, store(),
          DocumentsScreen(patient: patient, repository: repo(200, {'success': true, 'data': []})));
      expect(find.textContaining('has not stored any documents'), findsOneWidget);
    });
  });
}

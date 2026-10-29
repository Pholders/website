import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/appointments/data/appointments_repository.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_page.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_middleware.dart';
import 'package:redux/redux.dart';

/// Marking a consultation complete used to look like it did nothing: a
/// completed appointment the doctor had accepted still read "Accepted", the
/// dialog closed before the server answered, and a refusal was never shown.
Map<String, dynamic> row(String status, {bool accepted = true}) => {
      'id': 4,
      'patientId': 17,
      'patientName': 'Pule Test',
      'appointmentDate': '2026-10-29T00:00:00.000Z',
      'timeSlot': '09:00',
      'status': status,
      'doctorAccepted': accepted,
    };

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

class _FakeRepository extends AppointmentsRepository {
  _FakeRepository(this.status, {this.refusal})
      : super(ApiClient(tokenStorage: const _NoSession(), dio: Dio()));

  String status;
  final String? refusal;
  int completeCalls = 0;

  @override
  Future<List<Appointment>> fetch({
    AppointmentScope scope = AppointmentScope.all,
    int limit = 50,
    int offset = 0,
  }) async =>
      [Appointment.fromJson(row(status))];

  @override
  Future<void> complete(
    int appointmentId, {
    String? notes,
    String? diagnosis,
    bool prescriptionRequired = false,
  }) async {
    completeCalls++;
    if (refusal != null) throw ApiException(message: refusal!, statusCode: 400);
    status = 'completed';
  }
}

void main() {
  group('status label', () {
    test('a completed consultation says so even after it was accepted', () {
      expect(Appointment.fromJson(row('completed')).statusLabel, 'Completed');
    });

    test('a moved appointment is paid, so it can be completed', () {
      final a = Appointment.fromJson(row('rescheduled', accepted: false));
      expect(a.statusLabel, 'Rescheduled');
      expect(a.canComplete, isTrue);
    });

    test('an unpaid appointment cannot be completed', () {
      expect(Appointment.fromJson(row('pending_payment')).canComplete, isFalse);
    });
  });

  group('the appointment dialog', () {
    Future<_FakeRepository> show(WidgetTester tester, _FakeRepository repo) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAppointmentsMiddleware(repository: repo),
      );
      await tester.pumpWidget(StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: AppointmentsPage()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pule Test').first);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('completing says so and the card then reads Completed',
        (tester) async {
      final repo = await show(tester, _FakeRepository('scheduled'));
      await tester.tap(find.text('Mark complete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(repo.completeCalls, 1);
      expect(find.text('Consultation with Pule Test marked complete'), findsOneWidget);
      expect(find.text('Mark complete'), findsNothing); // dialog closed

      // A completed consultation moves to Past visits, reading Completed.
      await tester.tap(find.text('Past visits (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Pule Test'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets('a refusal from the server is shown, not swallowed',
        (tester) async {
      await show(tester, _FakeRepository('scheduled',
          refusal: 'This appointment is already completed.'));
      await tester.tap(find.text('Mark complete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(find.text('This appointment is already completed.'), findsOneWidget);
    });

    testWidgets('an unpaid appointment explains why it cannot be completed',
        (tester) async {
      await show(tester, _FakeRepository('pending_payment'));
      expect(find.text('Mark complete'), findsNothing);
      expect(find.textContaining('once the patient has paid'), findsOneWidget);
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/appointments/data/appointments_repository.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_page.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_middleware.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/shared/constants/app_constants.dart';
import 'package:pholders_app/shared/widgets/app_top_navbar.dart';
import 'package:redux/redux.dart';

/// The top bar's search was drawn as text and searched nothing. Doctors now
/// search on the pages that have something to search; Appointments and
/// Prescriptions gained a working one.
String day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime.utc(d.year, d.month, d.day).toIso8601String();
}

Map<String, dynamic> row(int id, String name, String date, {String? reason}) => {
      'id': id,
      'patientId': id,
      'patientName': name,
      'appointmentDate': date,
      'timeSlot': '09:00',
      'status': 'scheduled',
      'doctorAccepted': true,
      'reason': reason,
    };

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

class _FakeRepository extends AppointmentsRepository {
  _FakeRepository(this.rows)
      : super(ApiClient(tokenStorage: const _NoSession(), dio: Dio()));
  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Appointment>> fetch({
    AppointmentScope scope = AppointmentScope.all,
    int limit = 50,
    int offset = 0,
  }) async =>
      rows.map(Appointment.fromJson).toList();
}

void main() {
  group('Appointments search', () {
    Future<void> show(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAppointmentsMiddleware(
          repository: _FakeRepository([
            row(1, 'Naledi Khumalo', day(0), reason: 'Persistent cough'),
            row(2, 'Sipho Dube', day(0), reason: 'Back pain'),
            // Well outside this month, so only a search finds it.
            row(3, 'Lerato Molefe', day(70), reason: 'Check-up'),
          ]),
        ),
      );
      await tester.pumpWidget(StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: AppointmentsPage()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('finds a patient on any date, and the count follows', (tester) async {
      await show(tester);
      expect(find.text('Lerato Molefe'), findsNothing, reason: 'not in this month');

      await tester.enterText(find.byType(TextField), 'lerato');
      await tester.pumpAndSettle();
      expect(find.text('Lerato Molefe'), findsOneWidget);
      expect(find.text('Naledi Khumalo'), findsNothing);
      expect(find.text('Future visits (1)'), findsOneWidget);
      expect(find.text('All dates matching "lerato"'), findsOneWidget);
    });

    testWidgets('matches the reason for the visit too', (tester) async {
      await show(tester);
      await tester.enterText(find.byType(TextField), 'cough');
      await tester.pumpAndSettle();
      expect(find.text('Naledi Khumalo'), findsOneWidget);
      expect(find.text('Sipho Dube'), findsNothing);
    });

    testWidgets('says when nothing matches, and clearing brings the period back', (tester) async {
      await show(tester);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No upcoming visits match "zzz"'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Naledi Khumalo'), findsOneWidget);
      expect(find.text('Lerato Molefe'), findsNothing);
    });
  });

  group('Prescriptions search', () {
    const rx = Prescription(
      id: '15',
      patientName: 'Naledi Khumalo',
      medication: 'Lower respiratory tract infection',
      dosage: 'RX-1792996913382-621298A8',
      dateIssued: '22 Oct 2026',
      status: RxStatus.approved,
    );

    test('matches the patient, the diagnosis or the reference', () {
      expect(prescriptionMatches(rx, 'naledi'), isTrue);
      expect(prescriptionMatches(rx, 'respiratory'), isTrue);
      expect(prescriptionMatches(rx, '621298a8'), isTrue);
      expect(prescriptionMatches(rx, 'khumalo infection'), isTrue,
          reason: 'every word, in any field');
      expect(prescriptionMatches(rx, 'sipho'), isFalse);
      expect(prescriptionMatches(rx, '   '), isTrue, reason: 'empty matches all');
    });
  });

  group('the top bar', () {
    Future<void> show(WidgetTester tester, String role) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
        GoRoute(
          path: '/doctor/dashboard',
          builder: (_, __) => Scaffold(appBar: AppTopNavbar(role: role)),
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets("a doctor's has no search that searches nothing", (tester) async {
      await show(tester, AppConstants.roleDoctor);
      expect(find.textContaining('Search for'), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets("a pharmacy's is left as it was", (tester) async {
      await show(tester, AppConstants.rolePharmacy);
      expect(find.text('Search for patient or medication...'), findsOneWidget);
    });
  });
}

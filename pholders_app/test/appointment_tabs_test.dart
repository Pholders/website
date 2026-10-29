import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/appointments/data/appointments_repository.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_page.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_middleware.dart';
import 'package:redux/redux.dart';

/// The Future / Past / Planned tabs used to only change colour: all three
/// showed the same list, under a hard-coded "Future visits(20)".
String day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime.utc(d.year, d.month, d.day).toIso8601String();
}

Map<String, dynamic> row(int id, String name, String date, String status) => {
      'id': id,
      'patientId': id,
      'patientName': name,
      'appointmentDate': date,
      'timeSlot': '09:00',
      'status': status,
      'doctorAccepted': true,
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
  test('completed, or a day already gone, is a past visit', () {
    final now = DateTime.now();
    expect(Appointment.fromJson(row(1, 'A', day(-3), 'scheduled')).isPastAt(now), isTrue);
    expect(Appointment.fromJson(row(1, 'A', day(2), 'completed')).isPastAt(now), isTrue);
    expect(Appointment.fromJson(row(1, 'A', day(0), 'scheduled')).isPastAt(now), isFalse);
    expect(Appointment.fromJson(row(1, 'A', day(2), 'scheduled')).isPastAt(now), isFalse);
  });

  Future<void> show(WidgetTester tester, List<Map<String, dynamic>> rows) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = Store<AppState>(
      appReducer,
      initialState: AppState.initial(),
      middleware: createAppointmentsMiddleware(repository: _FakeRepository(rows)),
    );
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: const MaterialApp(home: AppointmentsPage()),
    ));
    await tester.pumpAndSettle();
  }

  final rows = [
    row(1, 'Future Patient', day(3), 'scheduled'),
    row(2, 'Seen Patient', day(-2), 'completed'),
    row(3, 'Missed Patient', day(-5), 'scheduled'),
  ];

  testWidgets('each tab shows its own visits, with real counts', (tester) async {
    await show(tester, rows);
    expect(find.text('Future visits (1)'), findsOneWidget);
    expect(find.text('Past visits (2)'), findsOneWidget);
    expect(find.text('Future Patient'), findsOneWidget);
    expect(find.text('Seen Patient'), findsNothing);

    await tester.tap(find.text('Past visits (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Seen Patient'), findsOneWidget);
    expect(find.text('Missed Patient'), findsOneWidget);
    expect(find.text('Future Patient'), findsNothing);
  });

  testWidgets('planned treatments says there are none instead of repeating the list',
      (tester) async {
    await show(tester, rows);
    await tester.tap(find.text('Planned Treatments'));
    await tester.pumpAndSettle();
    expect(find.text('No planned treatments yet'), findsOneWidget);
    expect(find.text('Future Patient'), findsNothing);
  });

  testWidgets('a doctor with no past visits is told so', (tester) async {
    await show(tester, [row(1, 'Future Patient', day(3), 'scheduled')]);
    await tester.tap(find.text('Past visits (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No past visits yet'), findsOneWidget);
  });
}

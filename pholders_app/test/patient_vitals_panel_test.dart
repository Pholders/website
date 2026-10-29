import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_vitals_panel.dart';

/// Vitals are taken by the doctor at a consultation. Any doctor the patient
/// booked sees them and records new ones, with no access request in between.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.routes);

  /// "METHOD /path" → (status, body)
  final Map<String, (int, Object)> routes;
  final List<String> seen = [];
  final Map<String, Object?> bodies = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    seen.add(key);
    bodies[key] = options.data;
    final (status, body) = routes[key] ?? (404, {'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  var signedOut = false;

  Future<void> show(WidgetTester tester, Map<String, (int, Object)> routes) async {
    server = _Server(routes);
    signedOut = false;
    final api = ApiClient(tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = server)
      ..onUnauthorized = () => signedOut = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PatientVitalsPanel(
            patientId: '20',
            repository: PatientRecordRepository(api),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  const vitalsKey = 'GET /users/phr/20/vitals';
  Map<String, Object> rows(List<Map<String, Object?>> data) => {'success': true, 'data': data};

  testWidgets('it reads vitals straight away, with no access request', (tester) async {
    await show(tester, {vitalsKey: (200, rows([]))});
    expect(server.seen, [vitalsKey]);
    expect(find.text('Ask for access'), findsNothing);
    expect(find.textContaining('No vitals recorded yet'), findsOneWidget);
    expect(find.text('Record vitals'), findsOneWidget);
  });

  testWidgets('it shows readings and who took them', (tester) async {
    await show(tester, {
      vitalsKey: (200, rows([
        {'measured_at': '2026-10-28T06:30:00Z', 'systolic_bp': 128, 'diastolic_bp': 84,
         'weight_kg': '81.20', 'bmi': '26.51', 'recorded_by_name': 'Dr Thandi Nkosi'},
        {'measured_at': '2026-10-20T06:30:00Z', 'heart_rate': 72},
      ])),
    });
    expect(find.text('128/84 mmHg', findRichText: true), findsOneWidget);
    expect(find.text('81.2 kg', findRichText: true), findsOneWidget);
    expect(find.text('26.5', findRichText: true), findsOneWidget);
    expect(find.text('Dr Thandi Nkosi'), findsOneWidget);
    // A reading from before doctors took over recording.
    expect(find.text('Logged by the patient'), findsOneWidget);
  });

  testWidgets('recording sends only what was filled in, then reloads', (tester) async {
    await show(tester, {
      vitalsKey: (200, rows([])),
      'POST /users/phr/20/vitals': (201, {'success': true, 'data': {
        'measured_at': '2026-10-29T08:00:00Z', 'systolic_bp': 120, 'diastolic_bp': 80, 'heart_rate': 70}}),
    });
    await tester.tap(find.text('Record vitals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Systolic BP'), '120');
    await tester.enterText(find.widgetWithText(TextFormField, 'Diastolic BP'), '80');
    await tester.enterText(find.widgetWithText(TextFormField, 'Heart rate'), '70');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(server.bodies['POST /users/phr/20/vitals'],
        {'systolic_bp': 120, 'diastolic_bp': 80, 'heart_rate': 70});
    expect(server.seen.where((k) => k == vitalsKey).length, 2);
    expect(find.text('Record vitals'), findsOneWidget); // dialog closed
  });

  testWidgets('an impossible value is caught before sending', (tester) async {
    await show(tester, {vitalsKey: (200, rows([]))});
    await tester.tap(find.text('Record vitals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Heart rate'), '9999');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('25–250 bpm'), findsOneWidget);
    expect(server.seen, isNot(contains('POST /users/phr/20/vitals')));
  });

  testWidgets('one blood pressure number on its own is refused', (tester) async {
    await show(tester, {vitalsKey: (200, rows([]))});
    await tester.tap(find.text('Record vitals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Systolic BP'), '120');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('both blood pressure numbers'), findsOneWidget);
    expect(server.seen, isNot(contains('POST /users/phr/20/vitals')));
  });

  testWidgets('a doctor the patient never booked is told so, not signed out', (tester) async {
    await show(tester, {
      vitalsKey: (403, {'success': false, 'message': 'You can see vitals only for patients who have booked with you'}),
    });
    expect(find.text('You can see vitals only for patients who have booked with you'), findsOneWidget);
    expect(signedOut, isFalse);
  });

  testWidgets('an expired session still signs the doctor out', (tester) async {
    await show(tester, {
      vitalsKey: (401, {'success': false, 'message': 'Session expired or revoked. Please login again.'}),
    });
    expect(signedOut, isTrue);
  });
}

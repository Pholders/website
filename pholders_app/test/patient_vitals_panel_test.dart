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

/// A doctor sees a patient's vitals only once the patient shares their health
/// record. Before that the panel offers to ask, and says where a request
/// stands; it never shows invented readings.
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    seen.add(key);
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

  Map<String, Object> status(String s, {bool canRequest = false}) =>
      {'success': true, 'data': {'status': s, 'canRequest': canRequest, 'requestedAt': '2026-10-28T09:00:00Z'}};

  testWidgets('without access it offers to ask and never asks for vitals', (tester) async {
    await show(tester, {'GET /users/phr/20/access-status': (200, status('none', canRequest: true))});
    expect(find.text('Ask for access'), findsOneWidget);
    expect(server.seen, isNot(contains('GET /users/phr/20/vitals')));
  });

  testWidgets('asking sends the request and shows it waiting', (tester) async {
    await show(tester, {
      'GET /users/phr/20/access-status': (200, status('none', canRequest: true)),
      'POST /users/phr/20/access-request': (201, status('pending')),
    });
    await tester.tap(find.text('Ask for access'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Follow-up on blood pressure');
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(server.seen, contains('POST /users/phr/20/access-request'));
    expect(find.textContaining('once they allow it'), findsOneWidget);
    expect(find.text('Ask for access'), findsNothing);
  });

  testWidgets('a declined request can be asked again', (tester) async {
    await show(tester, {'GET /users/phr/20/access-status': (200, status('denied', canRequest: true))});
    expect(find.textContaining('declined'), findsOneWidget);
    expect(find.text('Ask again'), findsOneWidget);
  });

  testWidgets('with access it shows the logged readings', (tester) async {
    await show(tester, {
      'GET /users/phr/20/access-status': (200, status('granted')),
      'GET /users/phr/20/vitals': (200, {
        'success': true,
        'data': [
          {'measured_at': '2026-10-28T06:30:00Z', 'systolic_bp': 128, 'diastolic_bp': 84, 'weight_kg': '81.20', 'bmi': '26.51'},
        ],
      }),
    });
    expect(find.text('128/84 mmHg', findRichText: true), findsOneWidget);
    expect(find.text('81.2 kg', findRichText: true), findsOneWidget);
    expect(find.text('26.5', findRichText: true), findsOneWidget);
  });

  testWidgets('a refusal from the server does not sign the doctor out', (tester) async {
    await show(tester, {
      'GET /users/phr/20/access-status': (200, status('granted')),
      'GET /users/phr/20/vitals': (403, {'success': false, 'message': 'You do not have access to this patient PHR'}),
    });
    expect(find.text('You do not have access to this patient PHR'), findsOneWidget);
    expect(signedOut, isFalse);
  });

  testWidgets('an expired session still signs the doctor out', (tester) async {
    await show(tester, {
      'GET /users/phr/20/access-status': (401, {'success': false, 'message': 'Session expired or revoked. Please login again.'}),
    });
    expect(signedOut, isTrue);
  });
}

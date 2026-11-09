import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

/// Answers every request with [status] and counts them by path.
class _Server implements HttpClientAdapter {
  int status = 200;
  final asked = <String, int>{};

  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    asked[o.path] = (asked[o.path] ?? 0) + 1;
    return ResponseBody.fromString(
      jsonEncode(status == 200
          ? {'success': true, 'data': []}
          : {'success': false, 'message': 'No'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A patient's record is fetched once a session, however many screens ask.
void main() {
  late _Server server;
  late PatientRecordRepository repo;

  setUp(() {
    server = _Server();
    repo = PatientRecordRepository(ApiClient(
        tokenStorage: const _NoSession(),
        dio: Dio()..httpClientAdapter = server));
  });

  int asked(String path) => server.asked[path] ?? 0;

  test('asking again is answered without a request', () async {
    await repo.fetchMedications('7');
    await repo.fetchMedications('7');
    await repo.fetchHistory('7');
    await repo.fetchHistory('7');
    expect(asked('/users/phr/7/medications'), 1);
    expect(asked('/users/phr/7/history'), 1);
  });

  test('prefetch loads the whole profile ahead of time', () async {
    expect(repo.hasFetched('7'), isFalse);
    await repo.prefetch('7');
    expect(repo.hasFetched('7'), isTrue);
    await repo.fetchVitals('7');
    await repo.fetchDocuments('7');
    expect(asked('/users/phr/7/vitals'), 1);
    expect(asked('/users/phr/7/documents'), 1);
  });

  test('a passing failure is tried again; a refusal is not', () async {
    server.status = 500;
    await expectLater(repo.fetchHistory('7'), throwsA(isA<ApiException>()));
    await pumpEventQueue();
    server.status = 200;
    await repo.fetchHistory('7');
    expect(asked('/users/phr/7/history'), 2);

    server.status = 403;
    await expectLater(repo.fetchHistory('8'), throwsA(isA<ApiException>()));
    await pumpEventQueue();
    await expectLater(repo.fetchHistory('8'), throwsA(isA<ApiException>()));
    expect(asked('/users/phr/8/history'), 1);
  });

  test('recording vitals refreshes them; signing out forgets all', () async {
    await repo.fetchVitals('7');
    await repo.recordVitals('7', {'heart_rate': 70});
    await repo.fetchVitals('7');
    expect(asked('/users/phr/7/vitals'), 3); // read, record, read again

    await repo.fetchMedications('7');
    repo.clear();
    await repo.fetchMedications('7');
    expect(asked('/users/phr/7/medications'), 2);
  });
}

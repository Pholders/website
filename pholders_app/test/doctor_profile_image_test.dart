import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';

/// Secure storage is a platform plugin and unavailable here; the token is not
/// what these tests are about.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

/// Captures what the repository actually puts on the wire, so the contract
/// Prince published — PUT, multipart, field `image`, a real image content
/// type — is held in place by a test rather than by memory.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.respond);

  final ResponseBody Function() respond;
  RequestOptions? seen;
  List<int> body = const [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = chunks.expand((c) => c).toList();
    }
    return respond();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String text, int status) => ResponseBody.fromString(
      text,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late _CapturingAdapter adapter;
  late DoctorAuthRepository repository;

  void arrange(String json, {int status = 200}) {
    adapter = _CapturingAdapter(() => _json(json, status));
    final dio = Dio()..httpClientAdapter = adapter;
    repository = DoctorAuthRepository(
      ApiClient(tokenStorage: const _NoSession(), dio: dio),
    );
  }

  const ok = '{"success":true,"message":"Profile image updated successfully",'
      '"data":{"profile_image":"https://api.test/api/users/doctor/profile-images/doctor_17_1.png"}}';

  test('uploads to the endpoint Prince published, as a PUT', () async {
    arrange(ok);
    await repository.uploadProfileImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'face.png',
      contentType: 'image/png',
    );

    expect(adapter.seen!.method, 'PUT');
    expect(adapter.seen!.path, '/users/doctor/profile/image');
  });

  test('sends it as multipart under the field name "image"', () async {
    arrange(ok);
    await repository.uploadProfileImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'face.png',
      contentType: 'image/png',
    );

    final contentType = adapter.seen!.headers[Headers.contentTypeHeader].toString();
    expect(contentType, contains('multipart/form-data'));

    final sent = String.fromCharCodes(adapter.body);
    expect(sent, contains('name="image"'));
    expect(sent, contains('filename="face.png"'));
  });

  test('labels the part with a real image type, never octet-stream', () async {
    arrange(ok);
    await repository.uploadProfileImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'face.webp',
      contentType: 'image/webp',
    );

    final sent = String.fromCharCodes(adapter.body);
    // The server's filter reads this; Dio's default would be rejected.
    expect(sent, contains('image/webp'));
    expect(sent, isNot(contains('application/octet-stream')));
  });

  test('returns the URL the server says the image now lives at', () async {
    arrange(ok);
    final url = await repository.uploadProfileImage(
      bytes: Uint8List.fromList([1]),
      filename: 'a.png',
      contentType: 'image/png',
    );
    expect(url, 'https://api.test/api/users/doctor/profile-images/doctor_17_1.png');
  });

  test('surfaces the server\'s own message when it refuses the file', () async {
    arrange('{"success":false,"message":"No image file provided (field: image)"}', status: 400);
    expect(
      () => repository.uploadProfileImage(
        bytes: Uint8List.fromList([1]),
        filename: 'a.png',
        contentType: 'image/png',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No image file provided'),
        ),
      ),
    );
  });

  test('does not claim success when the URL is missing from the response', () async {
    arrange('{"success":true,"message":"ok","data":{}}');
    expect(
      () => repository.uploadProfileImage(
        bytes: Uint8List.fromList([1]),
        filename: 'a.png',
        contentType: 'image/png',
      ),
      throwsA(isA<ApiException>()),
    );
  });
}

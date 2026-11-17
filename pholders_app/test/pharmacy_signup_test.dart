import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_middleware.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';
import 'package:pholders_app/features/auth/data/pharmacy_auth_repository.dart';
import 'package:redux/redux.dart';

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

/// Answers every request with [reply] and keeps what was sent.
class _Server implements HttpClientAdapter {
  _Server(this.reply, {this.status = 200});
  final Map<String, Object?> reply;
  final int status;
  final sent = <String, Map<String, dynamic>>{};

  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    sent['${o.method} ${o.path}'] =
        o.data is Map ? Map<String, dynamic>.from(o.data as Map) : {};
    return ResponseBody.fromString(jsonEncode(reply), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Pharmacy signup, at the endpoints and with the fields the backend's
/// controller takes (the Swagger docs are out of date).
void main() {
  late _Server server;

  ApiClient api(_Server s) => ApiClient(
      tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = s);

  Store<AppState> storeWith(_Server s) => Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAuthMiddleware(
          doctorAuth: DoctorAuthRepository(api(s)),
          pharmacyAuth: PharmacyAuthRepository(api(s)),
          tokenStorage: const _NoSession(),
        ),
      );

  const signup = PharmacySignupRequestAction(
    pharmacyName: 'HealthPlus Pharmacy',
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane@healthplus.co.za',
    phone: '0821234567',
    password: 'StrongP@ssw0rd!',
    licenseNumber: 'PH-12345',
    city: 'Johannesburg',
    province: 'Gauteng',
  );

  test('signup sends all nine fields, by their backend names', () async {
    server = _Server({'success': true, 'message': 'Check your email'});
    final store = storeWith(server);
    store.dispatch(signup);
    await pumpEventQueue();

    expect(server.sent['POST /users/pharmacy/signup'], {
      'pharmacy_name': 'HealthPlus Pharmacy',
      'first_name': 'Jane',
      'last_name': 'Doe',
      'email': 'jane@healthplus.co.za',
      'phone': '0821234567',
      'password': 'StrongP@ssw0rd!',
      'license_number': 'PH-12345',
      'city': 'Johannesburg',
      'province': 'Gauteng',
    });
    // On to the code, as a pharmacy.
    expect(store.state.authState.signupEmail, 'jane@healthplus.co.za');
    expect(store.state.authState.isPharmacySignup, isTrue);
  });

  test("a pharmacy's code is checked at verify-otp, as otp_code", () async {
    server = _Server({'success': true, 'message': 'Activated'});
    final store = storeWith(server);
    store.dispatch(signup);
    await pumpEventQueue();

    store.dispatch(const VerifyEmailRequestAction(
        email: 'jane@healthplus.co.za', otpCode: '123456'));
    await pumpEventQueue();
    expect(server.sent['POST /users/pharmacy/verify-otp'],
        {'email': 'jane@healthplus.co.za', 'otp_code': '123456'});
    expect(
        server.sent.keys, isNot(contains('POST /users/doctor/verify-email')));
    expect(store.state.authState.isEmailVerified, isTrue);
  });

  test("a pharmacy's code is resent at the pharmacy endpoint", () async {
    server = _Server({'success': true, 'message': 'If the account exists…'});
    final store = storeWith(server);
    store.dispatch(signup);
    await pumpEventQueue();

    store.dispatch(
        const RequestVerificationOtpAction(email: 'jane@healthplus.co.za'));
    await pumpEventQueue();
    expect(server.sent['POST /users/pharmacy/resend-verification'],
        {'email': 'jane@healthplus.co.za'});
  });

  test("the server's refusal is shown, with its field errors", () async {
    server = _Server({
      'success': false,
      'message': 'Email or license number already registered',
    }, status: 409);
    final store = storeWith(server);
    store.dispatch(signup);
    await pumpEventQueue();
    expect(store.state.authState.errorMessage,
        'Email or license number already registered');
    expect(store.state.authState.signupEmail, isNull);
  });

  test('a development-mode code is surfaced', () async {
    server = _Server({'success': true, 'verification_code': '654321'});
    final store = storeWith(server);
    store.dispatch(signup);
    await pumpEventQueue();
    expect(store.state.authState.devOtpCode, '654321');
  });

  test('a doctor still verifies at the doctor endpoint', () async {
    server = _Server({'success': true});
    final store = storeWith(server);
    store.dispatch(const VerifyEmailRequestAction(
        email: 'thandi@example.com', otpCode: '111111'));
    await pumpEventQueue();
    expect(server.sent.keys, contains('POST /users/doctor/verify-email'));
  });
}

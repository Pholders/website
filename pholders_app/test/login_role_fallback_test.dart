import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/auth_middleware.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/features/auth/data/pharmacy_auth_repository.dart';
import 'package:pholders_app/shared/constants/app_constants.dart';
import 'package:redux/redux.dart';

/// The login form no longer asks "Doctor or Pharmacy?". With no role, the
/// middleware tries the doctor login and falls back to the pharmacy one only
/// when the doctor endpoint turns the credentials down.

class _MemoryStorage extends TokenStorage {
  _MemoryStorage() : super(const FlutterSecureStorage());

  String? savedRole;

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveSession({
    required String token,
    required String role,
    required String userName,
  }) async =>
      savedRole = role;
}

ApiException _status(int code, String message) => ApiException(
      message: message,
      statusCode: code,
      kind: ApiErrorKind.http,
    );

const _offline = ApiException(
  message: 'No connection',
  kind: ApiErrorKind.network,
);

class _Doctors extends DoctorAuthRepository {
  _Doctors(TokenStorage storage, {this.failWith})
      : super(ApiClient(tokenStorage: storage));

  final ApiException? failWith;
  int logins = 0;

  @override
  Future<DoctorSession> login({
    required String email,
    required String password,
  }) async {
    logins++;
    if (failWith != null) throw failWith!;
    return const DoctorSession(
      token: 'doctor-token',
      doctor: Doctor(id: 1, firstName: 'Thandi', lastName: 'Nkosi', email: 'd@x'),
    );
  }

  @override
  Future<Doctor> fetchProfile() async => throw _status(500, 'skip');
}

class _Pharmacies extends PharmacyAuthRepository {
  _Pharmacies(TokenStorage storage, {this.failWith})
      : super(ApiClient(tokenStorage: storage));

  final ApiException? failWith;
  int logins = 0;

  @override
  Future<PharmacySession> login({
    required String email,
    required String password,
  }) async {
    logins++;
    if (failWith != null) throw failWith!;
    return const PharmacySession(
      token: 'pharmacy-token',
      pharmacyName: 'Corner Pharmacy',
      pharmacyId: 9,
    );
  }
}

void main() {
  late _MemoryStorage storage;

  Future<Store<AppState>> signIn(_Doctors doctors, _Pharmacies pharmacies) async {
    final store = Store<AppState>(
      appReducer,
      initialState: AppState.initial(),
      middleware: createAuthMiddleware(
        doctorAuth: doctors,
        pharmacyAuth: pharmacies,
        tokenStorage: storage,
      ),
    );
    store.dispatch(const LoginRequestAction(email: 'a@b.c', password: 'pw'));
    await pumpEventQueue();
    return store;
  }

  setUp(() => storage = _MemoryStorage());

  test('a doctor signs in without trying the pharmacy login', () async {
    final doctors = _Doctors(storage);
    final pharmacies = _Pharmacies(storage);
    final store = await signIn(doctors, pharmacies);

    expect(store.state.authState.role, AppConstants.roleDoctor);
    expect(storage.savedRole, AppConstants.roleDoctor);
    expect(pharmacies.logins, 0);
  });

  test('credentials the doctor login rejects are tried as a pharmacy',
      () async {
    final doctors = _Doctors(storage, failWith: _status(401, 'Wrong password'));
    final pharmacies = _Pharmacies(storage);
    final store = await signIn(doctors, pharmacies);

    expect(store.state.authState.role, AppConstants.rolePharmacy);
    expect(store.state.authState.userName, 'Corner Pharmacy');
    expect(storage.savedRole, AppConstants.rolePharmacy);
    expect(store.state.authState.errorMessage, isNull);
  });

  test('when neither knows the credentials, the doctor message is shown',
      () async {
    final doctors =
        _Doctors(storage, failWith: _status(401, 'Invalid email or password'));
    final pharmacies =
        _Pharmacies(storage, failWith: _status(404, 'Pharmacy not found'));
    final store = await signIn(doctors, pharmacies);

    expect(store.state.authState.isLoading, isFalse);
    expect(store.state.authState.token, isNull);
    expect(store.state.authState.errorMessage, 'Invalid email or password');
  });

  test('a pharmacy outage is reported instead of the doctor rejection',
      () async {
    final doctors = _Doctors(storage, failWith: _status(401, 'Wrong password'));
    final pharmacies = _Pharmacies(storage, failWith: _status(503, 'Down'));
    final store = await signIn(doctors, pharmacies);

    expect(store.state.authState.errorMessage, 'Down');
  });

  test('a network failure on the doctor login does not try the pharmacy',
      () async {
    final doctors = _Doctors(storage, failWith: _offline);
    final pharmacies = _Pharmacies(storage);
    final store = await signIn(doctors, pharmacies);

    expect(pharmacies.logins, 0);
    expect(store.state.authState.errorMessage, 'No connection');
  });
}

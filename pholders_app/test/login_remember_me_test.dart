import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
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
import 'package:pholders_app/features/auth/presentation/widgets/login_panel.dart';
import 'package:redux/redux.dart';

/// "Remember me" fills in the email that last signed in. Ticking it, or
/// clicking its words, and signing in keeps it; unticked, it is forgotten.
/// The app never keeps the password.
class Memory extends TokenStorage {
  Memory({this.email}) : super(const FlutterSecureStorage());
  String? email;

  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> saveSession({
    required String token,
    required String role,
    required String userName,
  }) async {}

  @override
  Future<String?> readRememberedEmail() async => email;
  @override
  Future<void> rememberEmail(String? value) async => email = value;
}

const _wrong = ApiException(
  message: 'Invalid email or password',
  statusCode: 401,
  kind: ApiErrorKind.http,
);

class _Doctors extends DoctorAuthRepository {
  _Doctors(TokenStorage s) : super(ApiClient(tokenStorage: s));
  static const _password = 'secret';

  @override
  Future<DoctorSession> login({
    required String email,
    required String password,
  }) async {
    if (password != _password) throw _wrong;
    return const DoctorSession(
      token: 't',
      doctor:
          Doctor(id: 1, firstName: 'Thandi', lastName: 'Nkosi', email: 'd@x'),
    );
  }

  @override
  Future<Doctor> fetchProfile() async => throw _wrong;
}

class _Pharmacies extends PharmacyAuthRepository {
  _Pharmacies(TokenStorage s) : super(ApiClient(tokenStorage: s));

  @override
  Future<PharmacySession> login({
    required String email,
    required String password,
  }) async =>
      throw _wrong;
}

void main() {
  group('the login form', () {
    late List<Object?> dispatched;

    Future<void> show(WidgetTester tester, Memory storage) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      dispatched = [];
      final store = Store<AppState>(
        (s, a) {
          dispatched.add(a);
          return s;
        },
        initialState: AppState.initial(),
      );
      await tester.pumpWidget(StoreProvider<AppState>(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: LoginPanel(fieldWidth: 360, storage: storage)),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Finder field(String hint) => find.widgetWithText(TextFormField, hint);
    String text(WidgetTester tester, String hint) =>
        tester.widget<TextFormField>(field(hint)).controller!.text;
    bool ticked(WidgetTester tester) =>
        tester.widget<Checkbox>(find.byType(Checkbox)).value!;

    testWidgets('a remembered email is filled in, never a password',
        (tester) async {
      await show(tester, Memory(email: 'naledi@example.test'));

      expect(text(tester, 'Email address'), 'naledi@example.test');
      expect(text(tester, 'Password'), isEmpty);
      expect(ticked(tester), isTrue);
    });

    testWidgets('with nothing remembered the form starts empty',
        (tester) async {
      await show(tester, Memory());

      expect(text(tester, 'Email address'), isEmpty);
      expect(text(tester, 'Password'), isEmpty);
      expect(ticked(tester), isFalse);
    });

    testWidgets('clicking the words "Remember me" ticks and unticks the box',
        (tester) async {
      await show(tester, Memory());

      await tester.tap(find.text('Remember me'));
      await tester.pump();
      expect(ticked(tester), isTrue);
      await tester.tap(find.text('Remember me'));
      await tester.pump();
      expect(ticked(tester), isFalse);
    });

    testWidgets('signing in passes on whether to remember', (tester) async {
      await show(tester, Memory());
      await tester.enterText(field('Email address'), ' naledi@example.test ');
      await tester.enterText(field('Password'), 'secret');
      await tester.tap(find.text('Remember me'));
      await tester.tap(find.text("Let's start"));
      await tester.pump();

      final login = dispatched.whereType<LoginRequestAction>().single;
      expect(login.email, 'naledi@example.test');
      expect(login.rememberMe, isTrue);
    });
  });

  group('signing in', () {
    Future<void> signIn(Memory storage, String password, bool? remember) async {
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAuthMiddleware(
          doctorAuth: _Doctors(storage),
          pharmacyAuth: _Pharmacies(storage),
          tokenStorage: storage,
        ),
      );
      store.dispatch(LoginRequestAction(
        email: 'naledi@example.test',
        password: password,
        rememberMe: remember,
      ));
      await pumpEventQueue();
    }

    test('ticked, an email that signs in is kept, and no password', () async {
      final storage = Memory();
      await signIn(storage, 'secret', true);
      expect(storage.email, 'naledi@example.test');
    });

    test('ticked, an email that fails to sign in is not kept', () async {
      final storage = Memory();
      await signIn(storage, 'typo', true);
      expect(storage.email, isNull);
    });

    test('unticked, a kept email is forgotten', () async {
      final storage = Memory(email: 'naledi@example.test');
      await signIn(storage, 'secret', false);
      expect(storage.email, isNull);
    });

    test('a failed sign-in leaves a kept email alone', () async {
      final storage = Memory(email: 'naledi@example.test');
      await signIn(storage, 'typo', true);
      expect(storage.email, 'naledi@example.test');
    });
  });
}

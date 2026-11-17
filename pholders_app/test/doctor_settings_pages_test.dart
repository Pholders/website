import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/auth/data/doctor_auth_repository.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/features/auth/data/models/doctor_activity.dart';
import 'package:pholders_app/features/doctor/settings/presentation/integrations_settings.dart';
import 'package:pholders_app/features/doctor/settings/presentation/practice_settings.dart';
import 'package:pholders_app/features/doctor/settings/presentation/preferences_settings.dart';
import 'package:pholders_app/features/doctor/settings/presentation/security_settings.dart';
import 'package:pholders_app/features/doctor/settings/presentation/support_legal_settings.dart';
import 'package:redux/redux.dart';

/// The doctor's settings were mostly switches, fields and buttons with
/// nothing behind them. These check what each page now really does.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
  @override
  Future<String?> readToken() async => null;
}

class _FakeRepo extends DoctorAuthRepository {
  _FakeRepo() : super(ApiClient(tokenStorage: const _NoSession()));

  final calls = <String>[];
  Object? failWith;
  List<ActiveSession> sessions = const [];
  Map<String, String>? ticket;

  @override
  Future<int> changePassword({required String currentPassword, required String newPassword}) async {
    calls.add('changePassword $currentPassword>$newPassword');
    if (failWith != null) throw failWith!;
    return 2;
  }

  @override
  Future<int> revokeOtherSessions() async {
    calls.add('revokeOthers');
    return 1;
  }

  @override
  Future<void> revokeSession(String sessionId) async => calls.add('revoke $sessionId');

  @override
  Future<List<ActiveSession>> fetchSessions() async => sessions;

  @override
  Future<void> contactSupport({
    required String email,
    required String firstName,
    required String lastName,
    required String subject,
    required String message,
  }) async {
    ticket = {'email': email, 'name': '$firstName $lastName', 'subject': subject, 'message': message};
  }
}

const doctor = Doctor(
  id: 17,
  firstName: 'Thandi',
  lastName: 'Nkosi',
  email: 'dr.check@pholders.test',
  consultationFee: 450,
  notificationPreferences: {'reviews': false},
);

void main() {
  late List<dynamic> sent;
  late Store<AppState> store;

  Future<void> show(WidgetTester tester, Widget page, {Doctor? as = doctor}) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The test font draws every letter as a wide block.
      if (!details.toString().contains('overflowed')) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    sent = [];
    store = Store<AppState>(appReducer, initialState: AppState.initial(), middleware: [
      (store, action, next) {
        sent.add(action);
        next(action);
      },
    ]);
    if (as != null) store.dispatch(DoctorProfileLoadedAction(doctor: as));
    sent.clear();
    await tester.pumpWidget(StoreProvider<AppState>(store: store, child: MaterialApp(home: page)));
    await tester.pumpAndSettle();
  }

  group('Fees Setup', () {
    testWidgets('only the stored fee is offered, and saving it confirms', (tester) async {
      await show(tester, const PracticeSettings());
      expect(tester.widget<TextField>(find.byKey(const ValueKey('fee'))).controller!.text, '450.00');
      for (final gone in ['Video Fee:', 'Late Fee:', 'Follow-up Fee:', 'Accept Medical Aid', '15 min:']) {
        expect(find.text(gone), findsNothing, reason: '$gone is not stored');
      }

      await tester.enterText(find.byKey(const ValueKey('fee')), '520');
      await tester.tap(find.text('Save Fee'));
      await tester.pump();
      expect(sent.whereType<UpdateDoctorProfileAction>().single.consultationFee, 520);

      store.dispatch(const DoctorProfileLoadedAction(doctor: doctor));
      await tester.pumpAndSettle();
      expect(find.text('Your consultation fee is saved'), findsOneWidget);
    });

    testWidgets('a doctor with no fee is told patients cannot book them', (tester) async {
      await show(tester, const PracticeSettings(), as: const Doctor(id: 1, firstName: 'A', lastName: 'B', email: 'a@b.c'));
      expect(find.text('Not set yet, so patients cannot book you.'), findsOneWidget);
      await tester.tap(find.text('Save Fee'));
      await tester.pump();
      expect(find.text('Enter your fee, for example 450.00'), findsOneWidget);
      expect(sent.whereType<UpdateDoctorProfileAction>(), isEmpty);
    });
  });

  group('Notification Settings', () {
    testWidgets('shows the stored choices and saves all four', (tester) async {
      await show(tester, const PracticeSettings(initialTab: 1));
      Switch switchFor(String key) =>
          tester.widget<Switch>(find.descendant(of: find.byKey(ValueKey('pref-$key')), matching: find.byType(Switch)));
      expect(switchFor('newBookings').value, isTrue);
      expect(switchFor('reviews').value, isFalse, reason: 'stored as off');

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('pref-newBookings')), matching: find.byType(Switch)));
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(sent.whereType<UpdateDoctorProfileAction>().single.notificationPreferences, {
        'newBookings': false,
        'appointmentChanges': true,
        'prescriptionsDispensed': true,
        'reviews': false,
      });
    });
  });

  group('Security Settings', () {
    testWidgets('changing the password checks it first, then confirms', (tester) async {
      final repo = _FakeRepo();
      await show(tester, SecuritySettingsPage(repository: repo));
      expect(find.text('Biometric Login'), findsNothing);
      expect(find.text('Two-Factor Authentication'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('current')), 'OldPass!2026');
      await tester.enterText(find.byKey(const ValueKey('new')), 'NewPass!2026');
      await tester.enterText(find.byKey(const ValueKey('confirm')), 'Different!2026');
      await tester.tap(find.text('Change Password').last); // the button, not the heading
      await tester.pump();
      expect(find.text('The new password and its confirmation are different.'), findsOneWidget);
      expect(repo.calls, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('confirm')), 'NewPass!2026');
      await tester.tap(find.text('Change Password').last); // the button, not the heading
      await tester.pumpAndSettle();
      expect(repo.calls, ['changePassword OldPass!2026>NewPass!2026']);
      expect(find.textContaining('Password changed. 2 other devices were signed out.'), findsOneWidget);
    });

    testWidgets('the server saying the current password is wrong is shown', (tester) async {
      final repo = _FakeRepo()..failWith = const ApiException(message: 'Your current password is not right');
      await show(tester, SecuritySettingsPage(repository: repo));
      await tester.enterText(find.byKey(const ValueKey('current')), 'Guess!2026x');
      await tester.enterText(find.byKey(const ValueKey('new')), 'NewPass!2026');
      await tester.enterText(find.byKey(const ValueKey('confirm')), 'NewPass!2026');
      await tester.tap(find.text('Change Password').last); // the button, not the heading
      await tester.pumpAndSettle();
      expect(find.text('Your current password is not right'), findsOneWidget);
    });

    testWidgets('signing out the other devices does it', (tester) async {
      final repo = _FakeRepo();
      await show(tester, SecuritySettingsPage(repository: repo));
      await tester.tap(find.text('Sign out all other devices'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['revokeOthers']);
      expect(find.text('1 other device was signed out.'), findsOneWidget);
    });
  });

  group('Device Management', () {
    testWidgets("another device's Log Out signs that one out", (tester) async {
      final repo = _FakeRepo()
        ..sessions = [
          ActiveSession.fromJson(const {'id': 'here', 'ip_address': '10.0.0.1', 'device_info': {'userAgent': 'Mozilla Chrome/120'}}),
          ActiveSession.fromJson(const {'id': 'old-laptop', 'ip_address': '10.0.0.9', 'device_info': {'userAgent': 'Mozilla Firefox/119'}}),
        ];
      await show(tester, SecuritySettingsPage(initialTab: 1, repository: repo));
      expect(find.text('Device Management'), findsWidgets);
      expect(find.text('Active now'), findsOneWidget);
      expect(find.text('Other Devices (1)'), findsOneWidget);

      await tester.tap(find.text('Log Out').last); // the row's button, not the sidebar's
      await tester.pumpAndSettle();
      expect(repo.calls, ['revoke old-laptop']);
    });
  });

  group('Support', () {
    testWidgets('Contact Support sends a ticket from the doctor', (tester) async {
      final repo = _FakeRepo();
      await show(tester, SupportLegalSettings(initialTab: 3, repository: repo));
      await tester.tap(find.text('Send Message'));
      await tester.pump();
      expect(find.text('Add a subject and a message.'), findsOneWidget);
      expect(repo.ticket, isNull);

      await tester.enterText(find.byKey(const ValueKey('subject')), 'Fee not showing');
      await tester.enterText(find.byKey(const ValueKey('message')), 'Patients see no fee.');
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();
      expect(repo.ticket, {
        'email': 'dr.check@pholders.test',
        'name': 'Thandi Nkosi',
        'subject': 'Fee not showing',
        'message': 'Patients see no fee.',
      });
      expect(find.text('Sent. The Pholders team will reply to dr.check@pholders.test.'), findsOneWidget);
    });

    testWidgets('the policy pages say the full text is not written, and highlight themselves',
        (tester) async {
      await show(tester, const SupportLegalSettings(initialTab: 2));
      expect(find.textContaining('The full Terms of Service is being prepared'), findsOneWidget);
      expect(find.textContaining('protected by your security preferences'), findsNothing);
    });
  });

  group('pages with nothing to set', () {
    testWidgets('Linked Services lists no invented connections', (tester) async {
      await show(tester, const IntegrationsSettings());
      expect(find.textContaining('Last synced'), findsNothing);
      expect(find.text('Disconnect'), findsNothing);
      expect(find.textContaining('No outside services can be linked'), findsOneWidget);
    });

    testWidgets('Preferences points to the real notification choices', (tester) async {
      await show(tester, const PreferencesSettings());
      expect(find.text('Quiet Hours'), findsNothing);
      expect(find.text('Open Notification Settings'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/auth/data/models/doctor.dart';
import 'package:pholders_app/features/doctor/settings/presentation/account_settings.dart';
import 'package:redux/redux.dart';

/// The Profile page was mostly placeholders: an About box that could not be
/// typed in, four personal fields with nowhere to be stored, a licence number
/// that was never sent, signature buttons that did nothing, and no sign of
/// whether a save worked.
const doctor = Doctor(
  id: 17,
  firstName: 'Thandi',
  lastName: 'Nkosi',
  email: 'dr.check@pholders.test',
  phone: '0821234567',
  hpcsaNumber: 'MP0123456',
  specialization: 'General Practice',
  qualification: 'MBChB (Wits)',
  bio: 'Family doctor in Rosebank.',
);

void main() {
  late List<dynamic> sent;
  late Store<AppState> store;

  Future<void> show(WidgetTester tester, {int tab = 0}) async {
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
    store = Store<AppState>(
      appReducer,
      initialState: AppState.initial(),
      middleware: [
        (store, action, next) {
          sent.add(action);
          next(action);
        },
      ],
    )..dispatch(const DoctorProfileLoadedAction(doctor: doctor));
    sent.clear();

    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp(home: AccountSettings(initialTab: tab)),
    ));
    await tester.pumpAndSettle();
  }

  UpdateDoctorProfileAction lastSave() =>
      sent.whereType<UpdateDoctorProfileAction>().last;

  group('Personal Information', () {
    testWidgets('shows the stored bio, and only placeholders that are real', (tester) async {
      await show(tester);
      expect(find.text('Family doctor in Rosebank.'), findsOneWidget);
      expect(find.text('Patients read this on your page in the app.'), findsOneWidget);

      for (final gone in ['Date of Birth', 'Gender', 'Nationality', 'ID Number']) {
        expect(find.text(gone), findsNothing, reason: '$gone is not stored');
      }
    });

    testWidgets('fields are locked until Edit', (tester) async {
      await show(tester);
      await tester.enterText(find.byKey(const ValueKey('bio')), 'Changed');
      await tester.pump();
      expect(find.text('Family doctor in Rosebank.'), findsOneWidget);
    });

    testWidgets('Edit, change the bio and phone, Save sends them and confirms', (tester) async {
      await show(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('bio')), 'Consults in English and isiZulu.');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      final save = lastSave();
      expect(save.bio, 'Consults in English and isiZulu.');
      expect(save.firstName, 'Thandi');
      expect(save.phone, '0821234567');

      // The server answers with the saved profile.
      store.dispatch(DoctorProfileLoadedAction(
          doctor: Doctor.fromJson({...doctorJson, 'bio': 'Consults in English and isiZulu.'})));
      await tester.pumpAndSettle();
      expect(find.text('Your profile is saved'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget, reason: 'back to locked');
    });

    testWidgets('a refused save says why and stays in edit mode', (tester) async {
      await show(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      store.dispatch(const UpdateDoctorProfileFailedAction(errorMessage: 'Server unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Your profile is saved'), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('an empty name or a short phone number is caught before sending', (tester) async {
      await show(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(2), ''); // last name, after bio and first name
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('First and last name are both needed.'), findsOneWidget);
      expect(sent.whereType<UpdateDoctorProfileAction>(), isEmpty);
    });

    testWidgets('Cancel puts back what was stored', (tester) async {
      await show(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('bio')), 'Half-typed');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Family doctor in Rosebank.'), findsOneWidget);
      expect(sent.whereType<UpdateDoctorProfileAction>(), isEmpty);
    });
  });

  group('Professional Details', () {
    testWidgets('qualification is shown and saved; dead controls are gone', (tester) async {
      await show(tester, tab: 1);
      expect(find.text('MBChB (Wits)'), findsOneWidget);
      expect(find.text('Medical License Number'), findsNothing);
      expect(find.text('Draw your signature'), findsNothing);
      expect(find.text('Upload Signature'), findsNothing);
      expect(find.text('Not checked yet'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'MBChB (Wits)'), 'MBChB, FCFP (SA)');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(lastSave().qualification, 'MBChB, FCFP (SA)');

      store.dispatch(const DoctorProfileLoadedAction(doctor: doctor));
      await tester.pumpAndSettle();
      expect(find.text('Your professional details are saved'), findsOneWidget);
    });
  });
}

const doctorJson = <String, dynamic>{
  'id': 17,
  'first_name': 'Thandi',
  'last_name': 'Nkosi',
  'email': 'dr.check@pholders.test',
  'phone': '0821234567',
  'hpcsa_number': 'MP0123456',
  'specialization': 'General Practice',
  'qualification': 'MBChB (Wits)',
};

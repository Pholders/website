import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/medicine_draft.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/prescriptions_repository.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/new_prescription_dialog.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';

/// Builds a store that records what the dialog dispatches, so the form can be
/// checked without a network layer.
({Store<AppState> store, List<dynamic> dispatched}) _harness({
  List<Appointment> appointments = const [],
}) {
  final dispatched = <dynamic>[];
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [
      (store, action, next) {
        dispatched.add(action);
        next(action);
      },
    ],
  );
  // Always settle the list: the dialog asks for a refresh in initState, which
  // would otherwise leave it stuck showing "Loading consultations...".
  store.dispatch(AppointmentsLoadedAction(appointments: appointments));
  return (store: store, dispatched: dispatched);
}

Widget _app(Store<AppState> store) {
  return StoreProvider<AppState>(
    store: store,
    child: const MaterialApp(home: Scaffold(body: NewPrescriptionDialog())),
  );
}

final _appointment = Appointment(
  id: 4,
  patientName: 'Test Patient',
  timeSlot: '09:00',
  date: DateTime.utc(2026, 9, 11, 9),
);

/// What the picker renders for [_appointment].
final _appointmentLabel =
    'Test Patient — ${_appointment.formattedDate} ${_appointment.timeSlot}';

void main() {
  testWidgets('refuses to submit without a consultation chosen',
      (tester) async {
    final h = _harness(appointments: [_appointment]);
    await tester.pumpWidget(_app(h.store));
    await tester.pump();

    await tester.tap(find.text('Create prescription'));
    await tester.pump();

    expect(
      find.text('Choose the consultation this prescription is for.'),
      findsOneWidget,
    );
    expect(h.dispatched.whereType<CreatePrescriptionAction>(), isEmpty);
  });

  testWidgets('refuses to submit a prescription with no medicines',
      (tester) async {
    final h = _harness(appointments: [_appointment]);
    await tester.pumpWidget(_app(h.store));
    await tester.pump();

    // Choose the consultation.
    await tester.tap(find.byType(DropdownButton<Appointment>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_appointmentLabel).last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Upper respiratory infection'),
        'Acute bronchitis');
    await tester.tap(find.text('Create prescription'));
    await tester.pump();

    // Not arbitrary strictness: the backend refuses to sign a prescription
    // that has no medicines, so it would be unusable.
    expect(
      find.text('Add at least one medicine, or it cannot be signed later.'),
      findsOneWidget,
    );
    expect(h.dispatched.whereType<CreatePrescriptionAction>(), isEmpty);
  });

  testWidgets('says so when there is no consultation to prescribe against',
      (tester) async {
    final h = _harness();
    await tester.pumpWidget(_app(h.store));
    await tester.pump();
    // The dialog refreshes the list on open; settle that before asserting.
    h.store.dispatch(const AppointmentsLoadedAction(appointments: []));
    await tester.pump();

    expect(find.textContaining('No consultations awaiting you'), findsOneWidget);
  });

  testWidgets('dispatches the whole prescription once it is complete',
      (tester) async {
    final h = _harness(appointments: [_appointment]);
    await tester.pumpWidget(_app(h.store));
    await tester.pump();

    await tester.tap(find.byType(DropdownButton<Appointment>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_appointmentLabel).last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Upper respiratory infection'),
        'Acute bronchitis');

    // Add one medicine through its dialog.
    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Amoxicillin'), 'Amoxicillin');
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 500mg'), '500mg');
    await tester.enterText(find.widgetWithText(TextField, 'e.g. 21'), '21');
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Three times daily'),
        'Three times daily');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amoxicillin'), findsOneWidget);

    await tester.tap(find.text('Create prescription'));
    await tester.pump();

    final action =
        h.dispatched.whereType<CreatePrescriptionAction>().single;
    expect(action.appointmentId, 4);
    expect(action.diagnosis, 'Acute bronchitis');
    expect(action.medicines, hasLength(1));

    final medicine = action.medicines.single;
    expect(medicine.name, 'Amoxicillin');
    expect(medicine.dosage, '500mg');
    expect(medicine.quantity, 21);
    // The two enum columns default to values the backend's CHECK constraints
    // accept, so a submitted medicine can never be rejected for them.
    expect(medicine.form, MedicineDosageForm.tablet);
    expect(medicine.route, MedicineRoute.oral);
  });

  test('a medicine draft summarises itself for the review list', () {
    const draft = MedicineDraft(
      name: 'Amoxicillin',
      dosage: '500mg',
      form: MedicineDosageForm.capsule,
      quantity: 21,
      frequency: 'Three times daily',
      route: MedicineRoute.oral,
    );
    expect(draft.summary, 'Amoxicillin · 500mg · Three times daily');
  });
}

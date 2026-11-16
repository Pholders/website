import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/data/models/claimed_prescription.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/redux/dispensing_actions.dart';
import 'package:pholders_app/features/pharmacy/orders/data/models/pharmacy_order.dart';
import 'package:pholders_app/features/pharmacy/orders/redux/orders_actions.dart';
import 'package:pholders_app/features/pharmacy/prescriptions/data/pharmacy_script.dart';
import 'package:pholders_app/features/pharmacy/prescriptions/presentation/pharmacy_prescription_detail_page.dart';
import 'package:pholders_app/features/pharmacy/prescriptions/presentation/pharmacy_prescriptions_page.dart';

/// The shape `GET /prescriptions/pharmacy/claimed` returns.
ClaimedPrescription _script(int id,
        {String patient = 'Naledi Khumalo', String claimed = '2026-11-16T07:30:00Z'}) =>
    ClaimedPrescription.fromJson({
      'prescriptionId': id,
      'prescriptionNumber': 'RX-$id',
      'patientName': patient,
      'patientEmail': 'naledi@example.test',
      'patientPhone': '0845551234',
      'diagnosis': 'Chest infection',
      'claimedAt': claimed,
      'medicines': [
        {
          'name': 'Amoxicillin',
          'dosage': '500mg',
          'quantity': 21,
          'frequency': 'three times daily',
          'instructions': 'Finish the course',
        },
      ],
    });

/// The shape `GET /orders/pharmacy/queue` returns.
PharmacyOrder _order(int id, String number, String status,
        {String payment = 'self', String fulfilment = 'pickup'}) =>
    PharmacyOrder.fromJson({
      'id': id,
      'status': status,
      'payment_type': payment,
      'fulfillment_type': fulfilment,
      'total_amount': '250.00',
      'patient_first_name': 'Naledi',
      'patient_last_name': 'Khumalo',
      'prescription_number': number,
      'created_at': '2026-11-16T07:31:00Z',
    });

AppState _state({
  List<ClaimedPrescription> awaiting = const [],
  List<ClaimedPrescription> dispensed = const [],
  List<PharmacyOrder> orders = const [],
}) {
  final store = Store<AppState>(appReducer, initialState: AppState.initial());
  store.dispatch(
      DispensingQueueLoadedAction(awaiting: awaiting, dispensed: dispensed));
  store.dispatch(PharmacyOrdersLoadedAction(orders: orders));
  return store.state;
}

void main() {
  group('where a script is', () {
    test('a claim with no order yet, or a new order, is New', () {
      final rows = pharmacyScripts(_state(
        awaiting: [_script(1), _script(2)],
        orders: [_order(20, 'RX-2', 'pending')],
      ));
      expect(rows.map((r) => r.stage), everyElement(ScriptStage.newScript));
      expect(rows.every((r) => !r.patientNotified), isTrue);
    });

    test('the order sets the step, and the patient has been told', () {
      ScriptStage stageFor(String status) => pharmacyScripts(_state(
            awaiting: [_script(1)],
            orders: [_order(20, 'RX-1', status)],
          )).single.stage;
      expect(stageFor('accepted'), ScriptStage.accepted);
      expect(stageFor('preparing'), ScriptStage.inProgress);
      expect(stageFor('ready'), ScriptStage.ready);
      expect(stageFor('picked_up'), ScriptStage.collected);
      expect(stageFor('rejected'), ScriptStage.closed);

      final ready = pharmacyScripts(_state(
        awaiting: [_script(1)],
        orders: [_order(20, 'RX-1', 'ready')],
      )).single;
      expect(ready.patientNotified, isTrue);
      expect(ready.lastUpdateSent, 'Ready');
    });

    test('a dispensed script is Dispensed whatever its order says', () {
      final row = pharmacyScripts(_state(
        dispensed: [_script(1)],
        orders: [_order(20, 'RX-1', 'ready')],
      )).single;
      expect(row.stage, ScriptStage.dispensed);
    });

    test('a script claimed again after a closed order follows the live one', () {
      final row = pharmacyScripts(_state(
        awaiting: [_script(1)],
        orders: [
          _order(20, 'RX-1', 'cancelled'),
          _order(21, 'RX-1', 'preparing'),
        ],
      )).single;
      expect(row.order!.id, 21);
      expect(row.stage, ScriptStage.inProgress);
    });

    test('newest claim first', () {
      final rows = pharmacyScripts(_state(awaiting: [
        _script(1, claimed: '2026-11-10T08:00:00Z'),
        _script(2, claimed: '2026-11-16T08:00:00Z'),
      ]));
      expect(rows.map((r) => r.id), [2, 1]);
    });
  });

  group('the list', () {
    late Store<AppState> store;
    late List<Object> seen;

    Future<void> show(WidgetTester tester, Widget page) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      seen = [];
      store = Store<AppState>(
        (state, action) {
          seen.add(action);
          return appReducer(state, action);
        },
        initialState: AppState.initial(),
      );
      await tester.pumpWidget(StoreProvider<AppState>(
        store: store,
        child: MaterialApp(home: page),
      ));
      await tester.pump();
    }

    testWidgets('shows the claimed scripts, not sample rows', (tester) async {
      await show(tester, const PharmacyPrescriptionsPage());
      expect(seen.whereType<LoadDispensingQueueAction>(), isNotEmpty);
      expect(seen.whereType<LoadPharmacyOrdersAction>(), isNotEmpty);

      store.dispatch(DispensingQueueLoadedAction(
          awaiting: [_script(1)], dispensed: [_script(2, patient: 'Sipho Dube')]));
      store.dispatch(
          PharmacyOrdersLoadedAction(orders: [_order(20, 'RX-1', 'ready')]));
      await tester.pump();

      expect(find.text('Maria Wilson'), findsNothing);
      expect(find.text('Naledi Khumalo'), findsOneWidget);
      expect(find.text('Sipho Dube'), findsOneWidget);
      expect(find.text('Total: 2'), findsOneWidget);
      // The bell only where the patient has been sent an update.
      expect(find.byTooltip('Patient notified: Ready'), findsOneWidget);
    });

    testWidgets('a tab shows only that step', (tester) async {
      await show(tester, const PharmacyPrescriptionsPage());
      store.dispatch(DispensingQueueLoadedAction(
          awaiting: [_script(1)], dispensed: [_script(2, patient: 'Sipho Dube')]));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('scripts-tab-dispensed')));
      await tester.pump();
      expect(find.text('Sipho Dube'), findsOneWidget);
      expect(find.text('Naledi Khumalo'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('scripts-tab-ready')));
      await tester.pump();
      expect(find.text('Nothing is ready right now.'), findsOneWidget);
    });

    testWidgets('no claims yet says how they arrive', (tester) async {
      await show(tester, const PharmacyPrescriptionsPage());
      store.dispatch(
          const DispensingQueueLoadedAction(awaiting: [], dispensed: []));
      await tester.pump();
      expect(find.textContaining('when a patient claims one'), findsOneWidget);
    });

    testWidgets('the detail shows patient, medicines, payment and collection',
        (tester) async {
      await show(tester, const PharmacyPrescriptionDetailPage(prescriptionId: '1'));
      store.dispatch(
          DispensingQueueLoadedAction(awaiting: [_script(1)], dispensed: const []));
      store.dispatch(PharmacyOrdersLoadedAction(orders: [
        _order(20, 'RX-1', 'preparing',
            payment: 'medical_aid', fulfilment: 'delivery'),
      ]));
      await tester.pump();

      expect(find.text('RX-1'), findsOneWidget);
      expect(find.text('naledi@example.test'), findsOneWidget);
      expect(find.text('Amoxicillin'), findsOneWidget);
      expect(find.text('Finish the course'), findsOneWidget);
      expect(find.text('Medical aid'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.byKey(const ValueKey('patient-notified')), findsOneWidget);
      expect(find.text('Update the order'), findsOneWidget);
    });

    testWidgets('marking it dispensed asks first, then sends it', (tester) async {
      await show(tester, const PharmacyPrescriptionDetailPage(prescriptionId: '1'));
      store.dispatch(
          DispensingQueueLoadedAction(awaiting: [_script(1)], dispensed: const []));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('script-dispense')));
      await tester.pumpAndSettle();
      expect(seen.whereType<DispensePrescriptionAction>(), isEmpty);
      await tester.tap(find.byKey(const ValueKey('script-dispense-confirm')));
      await tester.pumpAndSettle();

      final sent = seen.whereType<DispensePrescriptionAction>().single;
      expect(sent.prescriptionId, 1);
      expect(find.text('Working…'), findsOneWidget);

      // The server moves it to dispensed.
      store.dispatch(
          DispensingQueueLoadedAction(awaiting: const [], dispensed: [_script(1)]));
      // The store's change arrives a frame after the dialog has gone.
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('script-dispensed')), findsOneWidget);
      expect(find.byKey(const ValueKey('script-dispense')), findsNothing);
    });

    testWidgets('a failed dispense says why', (tester) async {
      await show(tester, const PharmacyPrescriptionDetailPage(prescriptionId: '1'));
      store.dispatch(
          DispensingQueueLoadedAction(awaiting: [_script(1)], dispensed: const []));
      store.dispatch(const DispenseFailedAction(
          prescriptionId: 1, errorMessage: 'This prescription has expired'));
      await tester.pump();
      expect(find.text('This prescription has expired'), findsOneWidget);
    });

    testWidgets('a script that is not this pharmacy\'s says so', (tester) async {
      await show(tester, const PharmacyPrescriptionDetailPage(prescriptionId: '99'));
      store.dispatch(
          DispensingQueueLoadedAction(awaiting: [_script(1)], dispensed: const []));
      await tester.pump();
      expect(find.textContaining('not among the ones claimed'), findsOneWidget);
    });
  });
}

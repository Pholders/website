import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/pharmacy/dashboard/presentation/pharmacy_dashboard_page.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/data/models/claimed_prescription.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/redux/dispensing_actions.dart';
import 'package:pholders_app/features/pharmacy/orders/data/models/pharmacy_order.dart';
import 'package:pholders_app/features/pharmacy/orders/redux/orders_actions.dart';

PharmacyOrder _order(int id, String status, {String created = '2026-11-16T08:20:00Z'}) =>
    PharmacyOrder.fromJson({
      'id': id,
      'status': status,
      'payment_type': 'self',
      'fulfillment_type': 'pickup',
      'patient_first_name': 'Order',
      'patient_last_name': 'Patient$id',
      'prescription_number': 'RX-$id',
      'created_at': created,
    });

ClaimedPrescription _script(int id, String patient) =>
    ClaimedPrescription.fromJson({
      'prescriptionId': id,
      'prescriptionNumber': 'RX-SCRIPT-$id',
      'patientName': patient,
      'claimedAt': '2026-11-16T07:30:00Z',
      'medicines': [
        {'name': 'Amoxicillin'},
      ],
    });

void main() {
  late Store<AppState> store;
  late List<Object> seen;

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
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
    store.dispatch(const LoginSuccessAction(
        token: 't', role: 'pharmacy', userName: 'Bryanston Central'));
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        home: PharmacyDashboardPage(today: DateTime(2026, 11, 16)),
      ),
    ));
    await tester.pump();
  }

  String stat(WidgetTester tester, String label) {
    final column = find.byKey(ValueKey('dashboard-stat-$label'));
    final texts = tester
        .widgetList<Text>(find.descendant(of: column, matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    return texts[1]!; // label, value, subtitle
  }

  testWidgets('opening it asks for orders and claimed scripts', (tester) async {
    await show(tester);
    expect(seen.whereType<LoadPharmacyOrdersAction>(), isNotEmpty);
    expect(seen.whereType<LoadDispensingQueueAction>(), isNotEmpty);
  });

  testWidgets('before anything arrives it shows dashes, not made-up counts',
      (tester) async {
    await show(tester);
    expect(stat(tester, 'New Orders'), '–');
    expect(stat(tester, 'Pending Dispensing'), '–');
    expect(find.text('Maria Wilson'), findsNothing);
    expect(find.text('Saturday, 14th March'), findsNothing);
    expect(find.text('Monday, 16th November'), findsOneWidget);
  });

  testWidgets('the counts are the real orders and scripts', (tester) async {
    await show(tester);
    store.dispatch(PharmacyOrdersLoadedAction(orders: [
      _order(1, 'pending'),
      _order(2, 'pending'),
      _order(3, 'ready'),
      _order(4, 'picked_up'),
    ]));
    store.dispatch(DispensingQueueLoadedAction(
      awaiting: [_script(10, 'Naledi Khumalo')],
      dispensed: [_script(11, 'Sipho Dube'), _script(12, 'Thandi Mokoena')],
    ));
    await tester.pump();

    expect(stat(tester, 'New Orders'), '2');
    expect(stat(tester, 'Ready for Pickup'), '1');
    expect(stat(tester, 'Pending Dispensing'), '1');
    expect(stat(tester, 'Completed'), '2');
  });

  testWidgets('orders in progress are listed newest first; collected ones are not',
      (tester) async {
    await show(tester);
    store.dispatch(PharmacyOrdersLoadedAction(orders: [
      _order(1, 'pending', created: '2026-11-16T06:00:00Z'),
      _order(2, 'preparing', created: '2026-11-16T09:00:00Z'),
      _order(3, 'picked_up'),
    ]));
    await tester.pump();

    expect(find.byKey(const ValueKey('dashboard-order-3')), findsNothing);
    final first = tester.getTopLeft(find.byKey(const ValueKey('dashboard-order-2')));
    final second = tester.getTopLeft(find.byKey(const ValueKey('dashboard-order-1')));
    expect(first.dy, lessThan(second.dy));
    expect(find.text('Preparing'), findsOneWidget);
  });

  testWidgets('incoming prescriptions are the claimed scripts awaiting dispensing',
      (tester) async {
    await show(tester);
    store.dispatch(DispensingQueueLoadedAction(
      awaiting: [_script(10, 'Naledi Khumalo')],
      dispensed: const [],
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('dashboard-script-10')), findsOneWidget);
    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('RX-SCRIPT-10'), findsOneWidget);
    // No Accept button: accepting happens on the order, not here.
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('nothing waiting says so', (tester) async {
    await show(tester);
    store.dispatch(const PharmacyOrdersLoadedAction(orders: []));
    store.dispatch(
        const DispensingQueueLoadedAction(awaiting: [], dispensed: []));
    await tester.pump();
    expect(find.text('No orders in progress.'), findsOneWidget);
    expect(find.text('No claimed prescriptions waiting.'), findsOneWidget);
  });

  testWidgets('a failed load is shown, not hidden behind zeros', (tester) async {
    await show(tester);
    store.dispatch(const PharmacyOrdersFailedAction(
        errorMessage: 'The server is waking up'));
    await tester.pump();
    expect(find.text('The server is waking up'), findsOneWidget);
  });

  test('the date line reads the Figma way', () {
    expect(longDate(DateTime(2026, 11, 16)), 'Monday, 16th November');
    expect(longDate(DateTime(2026, 11, 1)), 'Sunday, 1st November');
    expect(longDate(DateTime(2026, 11, 12)), 'Thursday, 12th November');
    expect(longDate(DateTime(2026, 11, 23)), 'Monday, 23rd November');
  });
}

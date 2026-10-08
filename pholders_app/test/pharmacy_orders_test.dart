import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/pharmacy/orders/data/models/pharmacy_order.dart';
import 'package:pholders_app/features/pharmacy/orders/redux/orders_actions.dart';

/// The shape `GET /orders/pharmacy/queue` returns: raw snake_case columns
/// plus the joined patient name and script reference.
Map<String, dynamic> _order(Map<String, dynamic> extra) => {
      'id': 12,
      'status': 'pending',
      'payment_type': 'self',
      'fulfillment_type': 'pickup',
      'total_amount': null,
      'patient_responsibility': null,
      'patient_first_name': 'Thandi',
      'patient_last_name': 'Testpatient',
      'prescription_number': 'RX-1791441025728-068FDE87',
      'created_at': '2026-10-08T07:30:18.474Z',
      ...extra,
    };

void main() {
  group('PharmacyOrder', () {
    test('reads a new self-pay order', () {
      final o = PharmacyOrder.fromJson(_order({}));

      expect(o.id, 12);
      expect(o.status, OrderStatus.pending);
      expect(o.patientName, 'Thandi Testpatient');
      expect(o.reference, '#12');
      expect(o.isMedicalAid, isFalse);
      expect(o.totalLabel, '—', reason: 'nothing has been quoted yet');
    });

    test('an unquoted order does not read as free', () {
      final o = PharmacyOrder.fromJson(_order({'total_amount': null}));
      expect(o.totalLabel, isNot(contains('0.00')));
    });

    test('amounts arriving as strings still parse', () {
      // Postgres DECIMAL comes back as a string through this driver.
      final o = PharmacyOrder.fromJson(
        _order({'total_amount': '450.00', 'patient_responsibility': '120.50'}),
      );

      expect(o.totalLabel, 'R450.00');
      expect(o.dueLabel, 'R120.50');
    });

    test('the next step follows the backend state machine', () {
      expect(PharmacyOrder.fromJson(_order({'status': 'accepted'})).nextStatus,
          OrderStatus.preparing);
      expect(PharmacyOrder.fromJson(_order({'status': 'preparing'})).nextStatus,
          OrderStatus.ready);
      expect(PharmacyOrder.fromJson(_order({'status': 'ready'})).nextStatus,
          OrderStatus.pickedUp);
    });

    test('nothing is offered while a claim is out or the order is finished', () {
      expect(
        PharmacyOrder.fromJson(_order({'status': 'awaiting_claim'})).nextStatus,
        isNull,
        reason: 'the medical aid decides, not the pharmacy',
      );
      expect(PharmacyOrder.fromJson(_order({'status': 'picked_up'})).nextStatus,
          isNull);
      expect(PharmacyOrder.fromJson(_order({'status': 'rejected'})).nextStatus,
          isNull);
    });

    test('an unrecognised status does not masquerade as actionable', () {
      final o = PharmacyOrder.fromJson(_order({'status': 'something_new'}));

      expect(o.status, OrderStatus.unknown);
      expect(o.nextStatus, isNull);
    });

    test('statuses go back on the wire in the backend spelling', () {
      expect(OrderStatus.awaitingClaim.wireName, 'awaiting_claim');
      expect(OrderStatus.pickedUp.wireName, 'picked_up');
    });
  });

  group('pharmacy orders state', () {
    Store<AppState> store() =>
        Store<AppState>(appReducer, initialState: AppState.initial());

    test('an empty queue is told apart from one that has not loaded', () {
      final s = store();
      expect(s.state.pharmacyOrdersState.hasLoadedOnce, isFalse);

      s.dispatch(const PharmacyOrdersLoadedAction(orders: []));
      expect(s.state.pharmacyOrdersState.hasLoadedOnce, isTrue);
    });

    test('only the acted-on row is busy, and a failure frees it', () {
      final s = store();
      s.dispatch(const AcceptOrderAction(orderId: 12));
      expect(s.state.pharmacyOrdersState.busyIds, {12});

      s.dispatch(const OrderActionFailedAction(
        orderId: 12,
        errorMessage: 'Invalid transition',
      ));
      expect(s.state.pharmacyOrdersState.busyIds, isEmpty);
      expect(s.state.pharmacyOrdersState.errorMessage, 'Invalid transition');
    });

    test('signing out drops the previous pharmacy orders', () {
      final s = store();
      s.dispatch(PharmacyOrdersLoadedAction(
        orders: [PharmacyOrder.fromJson(_order({}))],
      ));
      s.dispatch(const LogoutAction());

      expect(s.state.pharmacyOrdersState.orders, isEmpty);
    });
  });
}

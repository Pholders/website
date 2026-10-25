import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/orders_repository.dart';
import 'orders_actions.dart';

/// Middleware performing the pharmacy order calls.
List<Middleware<AppState>> createPharmacyOrdersMiddleware({
  required OrdersRepository repository,
}) {
  Future<void> load(Store<AppState> store) async {
    try {
      final orders = await repository.fetchQueue();
      store.dispatch(PharmacyOrdersLoadedAction(orders: orders));
    } on ApiException catch (e) {
      store.dispatch(PharmacyOrdersFailedAction(errorMessage: e.message));
    }
  }

  /// Every order action changes the row's state, so the queue is refetched
  /// rather than patched in place — the backend's state machine decides what
  /// the order became, not the client.
  Future<void> run(
    Store<AppState> store,
    int orderId,
    Future<void> Function() call,
  ) async {
    try {
      await call();
    } on ApiException catch (e) {
      store.dispatch(
        OrderActionFailedAction(orderId: orderId, errorMessage: e.message),
      );
    }
    await load(store);
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);

    if (action is LoadPharmacyOrdersAction) {
      load(store);
    } else if (action is AcceptOrderAction) {
      run(store, action.orderId, () => repository.accept(
            action.orderId,
            totalAmount: action.totalAmount,
            patientResponsibility: action.patientResponsibility,
          ));
    } else if (action is RejectOrderAction) {
      run(store, action.orderId,
          () => repository.reject(action.orderId, reason: action.reason));
    } else if (action is SetOrderStatusAction) {
      run(store, action.orderId,
          () => repository.setStatus(action.orderId, status: action.status));
    }
  }

  return [middleware];
}

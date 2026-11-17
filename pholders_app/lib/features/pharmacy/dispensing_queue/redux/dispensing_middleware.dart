import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/dispensing_repository.dart';
import 'dispensing_actions.dart';

/// Middleware performing the pharmacy dispensing calls.
List<Middleware<AppState>> createDispensingMiddleware({
  required DispensingRepository repository,
}) {
  Future<void> load(Store<AppState> store) async {
    try {
      final awaiting = await repository.fetchClaimed();
      // History is secondary: a pharmacy can still work if it fails, so it
      // never takes the queue down with it.
      List<dynamic> dispensed = const [];
      try {
        dispensed = await repository.fetchDispensed();
      } on ApiException {
        dispensed = const [];
      }

      store.dispatch(DispensingQueueLoadedAction(
        awaiting: awaiting,
        dispensed: dispensed.cast(),
      ));
    } on ApiException catch (e) {
      store.dispatch(DispensingQueueFailedAction(errorMessage: e.message));
    }
  }

  Future<void> dispense(
    Store<AppState> store,
    DispensePrescriptionAction action,
  ) async {
    try {
      await repository.dispense(action.prescriptionId, notes: action.notes);
      // Dispensing moves it between both lists, so refetch rather than
      // guessing what the server now holds.
      await load(store);
    } on ApiException catch (e) {
      store.dispatch(DispenseFailedAction(
        prescriptionId: action.prescriptionId,
        errorMessage: e.message,
      ));
      await load(store);
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);
    if (action is LoadDispensingQueueAction) {
      load(store);
    } else if (action is DispensePrescriptionAction) {
      dispense(store, action);
    }
  }

  return [middleware];
}

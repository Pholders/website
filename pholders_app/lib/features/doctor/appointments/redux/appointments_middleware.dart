import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/appointments_repository.dart';
import 'appointments_actions.dart';

/// Middleware performing the appointment network calls.
List<Middleware<AppState>> createAppointmentsMiddleware({
  required AppointmentsRepository repository,
}) {
  Future<void> load(Store<AppState> store) async {
    try {
      final appointments = await repository.fetchPending();
      store.dispatch(AppointmentsLoadedAction(appointments: appointments));
    } on ApiException catch (e) {
      store.dispatch(AppointmentsLoadFailedAction(errorMessage: e.message));
    }
  }

  Future<void> accept(
    Store<AppState> store,
    AcceptAppointmentAction action,
  ) async {
    try {
      await repository.accept(action.appointmentId);
      // Accepting removes the appointment from this endpoint's filter, so
      // refetch rather than patching it in place.
      await load(store);
    } on ApiException catch (e) {
      store.dispatch(AcceptAppointmentFailedAction(
        appointmentId: action.appointmentId,
        errorMessage: e.message,
      ));
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);

    if (action is LoadAppointmentsAction) {
      load(store);
    } else if (action is AcceptAppointmentAction) {
      accept(store, action);
    }
  }

  return [middleware];
}

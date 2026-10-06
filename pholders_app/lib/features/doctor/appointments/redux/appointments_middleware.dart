import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/appointments_repository.dart';
import 'appointments_actions.dart';

/// Middleware performing the appointment network calls.
List<Middleware<AppState>> createAppointmentsMiddleware({
  required AppointmentsRepository repository,
}) {
  Future<void> load(
    Store<AppState> store, [
    AppointmentScope scope = AppointmentScope.all,
  ]) async {
    try {
      final appointments = await repository.fetch(scope: scope);
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
      // Accepting flips doctor_accepted, which changes which scopes the
      // appointment falls into, so refetch rather than patching in place.
      await load(store);
    } on ApiException catch (e) {
      store.dispatch(AcceptAppointmentFailedAction(
        appointmentId: action.appointmentId,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> complete(
    Store<AppState> store,
    CompleteAppointmentAction action,
  ) async {
    try {
      await repository.complete(
        action.appointmentId,
        notes: action.notes,
        diagnosis: action.diagnosis,
      );
      // A completed appointment drops out of this endpoint's filter.
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
      load(store, action.scope);
    } else if (action is AcceptAppointmentAction) {
      accept(store, action);
    } else if (action is CompleteAppointmentAction) {
      complete(store, action);
    }
  }

  return [middleware];
}

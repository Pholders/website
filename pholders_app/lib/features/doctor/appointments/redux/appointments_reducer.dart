import '../../../../core/auth/auth_actions.dart';
import 'appointments_actions.dart';
import 'appointments_state.dart';

/// Pure reducer for the appointments slice.
AppointmentsState appointmentsReducer(
  AppointmentsState state,
  dynamic action,
) {
  if (action is LoadAppointmentsAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is AppointmentsLoadedAction) {
    return state.copyWith(
      appointments: action.appointments,
      isLoading: false,
      hasLoadedOnce: true,
      clearError: true,
    );
  }

  if (action is AppointmentsLoadFailedAction) {
    return state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      errorMessage: action.errorMessage,
    );
  }

  if (action is AcceptAppointmentAction) {
    return state.copyWith(
      pendingActionIds: {...state.pendingActionIds, action.appointmentId},
      clearError: true,
    );
  }

  if (action is AcceptAppointmentFailedAction) {
    return state.copyWith(
      pendingActionIds: {...state.pendingActionIds}..remove(action.appointmentId),
      errorMessage: action.errorMessage,
    );
  }

  // Never leak one doctor's appointments into the next session.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return AppointmentsState.initial();
  }

  return state;
}

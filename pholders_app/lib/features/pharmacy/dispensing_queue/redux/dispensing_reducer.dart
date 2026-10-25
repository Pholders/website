import '../../../../core/auth/auth_actions.dart';
import 'dispensing_actions.dart';
import 'dispensing_state.dart';

DispensingState dispensingReducer(DispensingState state, dynamic action) {
  if (action is LoadDispensingQueueAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is DispensingQueueLoadedAction) {
    return state.copyWith(
      awaiting: action.awaiting,
      dispensed: action.dispensed,
      isLoading: false,
      hasLoadedOnce: true,
    );
  }

  if (action is DispensingQueueFailedAction) {
    return state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      errorMessage: action.errorMessage,
    );
  }

  if (action is DispensePrescriptionAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.prescriptionId},
      clearError: true,
    );
  }

  if (action is DispenseFailedAction) {
    return state.copyWith(
      busyIds: {...state.busyIds}..remove(action.prescriptionId),
      errorMessage: action.errorMessage,
    );
  }

  // One pharmacy's queue must never be shown to the next one who signs in.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return DispensingState.initial();
  }

  return state;
}

import '../../../../core/auth/auth_actions.dart';
import 'prescriptions_actions.dart';
import 'prescriptions_state.dart';

/// Pure reducer for the prescriptions slice.
PrescriptionsState prescriptionsReducer(
  PrescriptionsState state,
  dynamic action,
) {
  if (action is LoadPrescriptionsAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is PrescriptionsLoadedAction) {
    return state.copyWith(
      prescriptions: action.prescriptions,
      isLoading: false,
      hasLoadedOnce: true,
      busyIds: const {},
      clearError: true,
    );
  }

  if (action is PrescriptionsLoadFailedAction) {
    return state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      errorMessage: action.errorMessage,
    );
  }

  if (action is SignPrescriptionAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.prescriptionId},
      clearError: true,
    );
  }

  if (action is RevokePrescriptionAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.prescriptionId},
      clearError: true,
    );
  }

  if (action is PrescriptionActionFailedAction) {
    return state.copyWith(
      busyIds: {...state.busyIds}..remove(action.prescriptionId),
      errorMessage: action.errorMessage,
    );
  }

  // Never carry one doctor's prescriptions into the next session.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return PrescriptionsState.initial();
  }

  return state;
}

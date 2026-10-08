import '../../../../core/auth/auth_actions.dart';
import 'orders_actions.dart';
import 'orders_state.dart';

PharmacyOrdersState pharmacyOrdersReducer(
  PharmacyOrdersState state,
  dynamic action,
) {
  if (action is LoadPharmacyOrdersAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is PharmacyOrdersLoadedAction) {
    return state.copyWith(
      orders: action.orders,
      isLoading: false,
      hasLoadedOnce: true,
      busyIds: const {},
    );
  }

  if (action is PharmacyOrdersFailedAction) {
    return state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      errorMessage: action.errorMessage,
    );
  }

  if (action is AcceptOrderAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.orderId},
      clearError: true,
    );
  }

  if (action is RejectOrderAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.orderId},
      clearError: true,
    );
  }

  if (action is SetOrderStatusAction) {
    return state.copyWith(
      busyIds: {...state.busyIds, action.orderId},
      clearError: true,
    );
  }

  if (action is OrderActionFailedAction) {
    return state.copyWith(
      busyIds: {...state.busyIds}..remove(action.orderId),
      errorMessage: action.errorMessage,
    );
  }

  // One pharmacy's orders must never be shown to the next one who signs in.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return PharmacyOrdersState.initial();
  }

  return state;
}

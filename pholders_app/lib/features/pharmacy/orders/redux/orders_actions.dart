import '../data/models/pharmacy_order.dart';

/// Dispatched when the orders page opens or is refreshed.
class LoadPharmacyOrdersAction {
  const LoadPharmacyOrdersAction();
}

/// Dispatched when the queue arrives.
class PharmacyOrdersLoadedAction {
  const PharmacyOrdersLoadedAction({required this.orders});
  final List<PharmacyOrder> orders;
}

/// Dispatched when the queue cannot be loaded.
class PharmacyOrdersFailedAction {
  const PharmacyOrdersFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the pharmacy takes an order on.
class AcceptOrderAction {
  const AcceptOrderAction({
    required this.orderId,
    this.totalAmount,
    this.patientResponsibility,
  });
  final int orderId;
  final double? totalAmount;
  final double? patientResponsibility;
}

/// Dispatched when the pharmacy declines one.
///
/// The reason reaches the patient, so it is not optional here.
class RejectOrderAction {
  const RejectOrderAction({required this.orderId, required this.reason});
  final int orderId;
  final String reason;
}

/// Dispatched to move an order to its next state.
class SetOrderStatusAction {
  const SetOrderStatusAction({required this.orderId, required this.status});
  final int orderId;
  final OrderStatus status;
}

/// Dispatched when an order action fails, so the row can say why.
class OrderActionFailedAction {
  const OrderActionFailedAction({
    required this.orderId,
    required this.errorMessage,
  });
  final int orderId;
  final String errorMessage;
}

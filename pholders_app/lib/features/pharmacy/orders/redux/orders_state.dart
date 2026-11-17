import 'package:equatable/equatable.dart';

import '../data/models/pharmacy_order.dart';

/// The pharmacy orders slice of the Redux store.
class PharmacyOrdersState extends Equatable {
  const PharmacyOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.errorMessage,
    this.busyIds = const {},
  });

  factory PharmacyOrdersState.initial() => const PharmacyOrdersState();

  final List<PharmacyOrder> orders;
  final bool isLoading;

  /// False until the first fetch resolves, so an empty queue can be told
  /// apart from one that has not loaded.
  final bool hasLoadedOnce;

  final String? errorMessage;

  /// Orders with an accept, reject or transition in flight.
  final Set<int> busyIds;

  PharmacyOrdersState copyWith({
    List<PharmacyOrder>? orders,
    bool? isLoading,
    bool? hasLoadedOnce,
    String? errorMessage,
    Set<int>? busyIds,
    bool clearError = false,
  }) {
    return PharmacyOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busyIds: busyIds ?? this.busyIds,
    );
  }

  @override
  List<Object?> get props =>
      [orders, isLoading, hasLoadedOnce, errorMessage, busyIds];
}

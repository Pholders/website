import 'package:equatable/equatable.dart';

import '../data/models/prescription.dart';

/// The prescriptions slice of the Redux store.
class PrescriptionsState extends Equatable {
  const PrescriptionsState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.busyIds = const {},
    this.hasLoadedOnce = false,
  });

  factory PrescriptionsState.initial() => const PrescriptionsState();

  final List<Prescription> prescriptions;
  final bool isLoading;
  final String? errorMessage;

  /// Prescriptions with a sign or revoke call in flight.
  final Set<int> busyIds;

  /// False until the first fetch resolves, so the UI can tell "none yet"
  /// apart from "not fetched".
  final bool hasLoadedOnce;

  PrescriptionsState copyWith({
    List<Prescription>? prescriptions,
    bool? isLoading,
    String? errorMessage,
    Set<int>? busyIds,
    bool? hasLoadedOnce,
    bool clearError = false,
  }) {
    return PrescriptionsState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busyIds: busyIds ?? this.busyIds,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props =>
      [prescriptions, isLoading, errorMessage, busyIds, hasLoadedOnce];
}

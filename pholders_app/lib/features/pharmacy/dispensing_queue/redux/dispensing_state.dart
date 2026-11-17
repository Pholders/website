import 'package:equatable/equatable.dart';

import '../data/models/claimed_prescription.dart';

/// The pharmacy dispensing slice of the Redux store.
class DispensingState extends Equatable {
  const DispensingState({
    this.awaiting = const [],
    this.dispensed = const [],
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.errorMessage,
    this.busyIds = const {},
  });

  factory DispensingState.initial() => const DispensingState();

  /// Claimed here, not yet handed over.
  final List<ClaimedPrescription> awaiting;

  /// Already handed over.
  final List<ClaimedPrescription> dispensed;

  final bool isLoading;

  /// False until the first fetch resolves, so an empty queue can be told
  /// apart from one that has not loaded.
  final bool hasLoadedOnce;

  final String? errorMessage;

  /// Prescriptions with a dispense call in flight.
  final Set<int> busyIds;

  DispensingState copyWith({
    List<ClaimedPrescription>? awaiting,
    List<ClaimedPrescription>? dispensed,
    bool? isLoading,
    bool? hasLoadedOnce,
    String? errorMessage,
    Set<int>? busyIds,
    bool clearError = false,
  }) {
    return DispensingState(
      awaiting: awaiting ?? this.awaiting,
      dispensed: dispensed ?? this.dispensed,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busyIds: busyIds ?? this.busyIds,
    );
  }

  @override
  List<Object?> get props =>
      [awaiting, dispensed, isLoading, hasLoadedOnce, errorMessage, busyIds];
}

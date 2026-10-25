import 'package:equatable/equatable.dart';

import '../data/models/appointment.dart';

/// The appointments slice of the Redux store.
class AppointmentsState extends Equatable {
  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.pendingActionIds = const {},
    this.hasLoadedOnce = false,
  });

  factory AppointmentsState.initial() => const AppointmentsState();

  final List<Appointment> appointments;
  final bool isLoading;
  final String? errorMessage;

  /// Ids of appointments with an accept/complete call in flight, so each card
  /// can show its own spinner.
  final Set<int> pendingActionIds;

  /// False until the first fetch resolves, so the page can tell "empty"
  /// apart from "not fetched yet".
  final bool hasLoadedOnce;

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? errorMessage,
    Set<int>? pendingActionIds,
    bool? hasLoadedOnce,
    bool clearError = false,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingActionIds: pendingActionIds ?? this.pendingActionIds,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props =>
      [appointments, isLoading, errorMessage, pendingActionIds, hasLoadedOnce];
}

import 'package:equatable/equatable.dart';

import '../core/auth/auth_state.dart';
import '../features/doctor/appointments/redux/appointments_state.dart';
import '../features/doctor/prescriptions/redux/prescriptions_state.dart';

/// The root Redux state for the entire app.
///
/// Composes all feature-level state slices into one top-level store.
/// Each feature module owns its own slice and reducer.
class AppState extends Equatable {

  // Add more feature slices here as they are implemented:
  // final PatientsState patientsState;
  // final PrescriptionsState prescriptionsState;

  const AppState({
    required this.authState,
    required this.appointmentsState,
    required this.prescriptionsState,
  });

  /// The initial state when the app starts.
  factory AppState.initial() {
    return AppState(
      authState: AuthState.initial(),
      appointmentsState: AppointmentsState.initial(),
      prescriptionsState: PrescriptionsState.initial(),
    );
  }
  final AuthState authState;
  final AppointmentsState appointmentsState;
  final PrescriptionsState prescriptionsState;

  @override
  List<Object?> get props =>
      [authState, appointmentsState, prescriptionsState];
}

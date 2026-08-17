import 'package:equatable/equatable.dart';
import '../core/auth/auth_state.dart';

/// The root Redux state for the entire app.
///
/// Composes all feature-level state slices into one top-level store.
/// Each feature module owns its own slice and reducer.
class AppState extends Equatable {
  final AuthState authState;

  // Add more feature slices here as they are implemented:
  // final DashboardState dashboardState;
  // final PatientsState patientsState;
  // etc.

  const AppState({
    required this.authState,
  });

  /// The initial state when the app starts.
  factory AppState.initial() {
    return AppState(
      authState: AuthState.initial(),
    );
  }

  @override
  List<Object?> get props => [authState];
}

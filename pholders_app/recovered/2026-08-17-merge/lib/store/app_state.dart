import 'package:equatable/equatable.dart';

import '../core/auth/auth_state.dart';
import 'integration_state.dart';

/// The root Redux state for the entire app.
///
/// Composes all feature-level state slices into one top-level store.
/// Each feature module owns its own slice and reducer.
class AppState extends Equatable {
  const AppState({
    required this.authState,
    required this.integrationsState,
  });

  /// The initial state when the app starts.
  factory AppState.initial() {
    return AppState(
      authState: AuthState.initial(),
      integrationsState: IntegrationsState.initial(),
    );
  }

  final AuthState authState;
  final IntegrationsState integrationsState;

  @override
  List<Object?> get props => [authState, integrationsState];
}

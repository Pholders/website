import 'app_state.dart';
import '../core/auth/auth_reducer.dart';

/// Root reducer that combines all feature reducers.
///
/// Each feature module's reducer is called with its own slice of state.
/// This is the single function passed to the Redux [Store].
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    authState: authReducer(state.authState, action),
    // Add more reducers here as features are implemented:
    // dashboardState: dashboardReducer(state.dashboardState, action),
  );
}

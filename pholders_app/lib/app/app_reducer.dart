import 'app_state.dart';
import '../core/auth/auth_reducer.dart';
import '../features/doctor/appointments/redux/appointments_reducer.dart';
import '../features/doctor/prescriptions/redux/prescriptions_reducer.dart';

/// Root reducer that combines all feature reducers.
///
/// Each feature module's reducer is called with its own slice of state.
/// This is the single function passed to the Redux [Store].
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    authState: authReducer(state.authState, action),
    appointmentsState:
        appointmentsReducer(state.appointmentsState, action),
    prescriptionsState:
        prescriptionsReducer(state.prescriptionsState, action),
    // Add more reducers here as features are implemented:
    // patientsState: patientsReducer(state.patientsState, action),
  );
}

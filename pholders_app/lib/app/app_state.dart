import 'package:equatable/equatable.dart';
import '../features/pharmacy/orders/redux/orders_state.dart';
import '../features/pharmacy/dispensing_queue/redux/dispensing_state.dart';
import '../features/doctor/reviews/redux/reviews_state.dart';

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
    required this.reviewsState,
    required this.dispensingState,
    required this.pharmacyOrdersState,
  });

  /// The initial state when the app starts.
  factory AppState.initial() {
    return AppState(
      authState: AuthState.initial(),
      appointmentsState: AppointmentsState.initial(),
      prescriptionsState: PrescriptionsState.initial(),
      reviewsState: ReviewsState.initial(),
      dispensingState: DispensingState.initial(),
      pharmacyOrdersState: PharmacyOrdersState.initial(),
    );
  }
  final AuthState authState;
  final AppointmentsState appointmentsState;
  final PrescriptionsState prescriptionsState;
  final ReviewsState reviewsState;
  final DispensingState dispensingState;
  final PharmacyOrdersState pharmacyOrdersState;

  @override
  List<Object?> get props =>
      [authState, appointmentsState, prescriptionsState, reviewsState,
       dispensingState, pharmacyOrdersState];
}

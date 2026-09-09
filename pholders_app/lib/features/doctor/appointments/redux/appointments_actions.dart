import '../data/models/appointment.dart';

/// Dispatched when the appointments page opens or the user pulls to refresh.
class LoadAppointmentsAction {
  const LoadAppointmentsAction();
}

/// Dispatched by the middleware when the appointment list arrives.
class AppointmentsLoadedAction {
  const AppointmentsLoadedAction({required this.appointments});
  final List<Appointment> appointments;
}

/// Dispatched by the middleware when the appointment list fails to load.
class AppointmentsLoadFailedAction {
  const AppointmentsLoadFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the doctor accepts an appointment.
class AcceptAppointmentAction {
  const AcceptAppointmentAction({required this.appointmentId});
  final int appointmentId;
}

/// Dispatched when the doctor marks a consultation finished.
///
/// This finalises cash payment on the backend and can trigger the prescription
/// flow, so it cannot be undone from the app.
class CompleteAppointmentAction {
  const CompleteAppointmentAction({
    required this.appointmentId,
    this.notes,
    this.diagnosis,
  });
  final int appointmentId;
  final String? notes;
  final String? diagnosis;
}

/// Dispatched when accepting an appointment fails.
class AcceptAppointmentFailedAction {
  const AcceptAppointmentFailedAction({
    required this.appointmentId,
    required this.errorMessage,
  });
  final int appointmentId;
  final String errorMessage;
}

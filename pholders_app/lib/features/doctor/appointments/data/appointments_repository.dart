import '../../../../core/network/api_client.dart';
import 'models/appointment.dart';

/// Which slice of the doctor's appointments to fetch.
///
/// The endpoint used to return [inbox] and nothing else, which meant an
/// appointment vanished from the doctor's diary the moment they accepted it —
/// and with it the ability to write a prescription against it.
enum AppointmentScope {
  /// Bookings not yet accepted. The endpoint's original behaviour.
  inbox,

  /// Accepted and still ahead of today.
  upcoming,

  /// Everything bar cancellations, which is what a diary wants.
  all,
}

/// Doctor-side appointment calls.
class AppointmentsRepository {
  const AppointmentsRepository(this._api);

  final ApiClient _api;

  /// Fetches the doctor's appointments.
  ///
  /// A backend that predates the `scope` parameter ignores it and returns the
  /// inbox, so this degrades to the old behaviour rather than failing.
  Future<List<Appointment>> fetch({
    AppointmentScope scope = AppointmentScope.all,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/users/doctor/appointments',
      queryParameters: {'limit': limit, 'offset': offset, 'scope': scope.name},
    );

    final list = data['appointments'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Appointment.fromJson)
        .toList();
  }

  /// Acknowledges an appointment ahead of the consultation.
  Future<void> accept(int appointmentId) async {
    await _api.post(
      '/users/appointments/$appointmentId/accept',
      body: {'appointmentId': appointmentId},
    );
  }

  /// Marks an appointment complete after the consultation.
  ///
  /// This also finalises cash payment on the backend and can trigger the
  /// prescription flow, so it is not reversible from the client.
  Future<void> complete(
    int appointmentId, {
    String? notes,
    String? diagnosis,
    bool prescriptionRequired = false,
  }) async {
    await _api.post(
      '/users/appointments/$appointmentId/complete',
      body: {
        'appointmentId': appointmentId,
        if (notes != null) 'notes': notes,
        if (diagnosis != null) 'diagnosis': diagnosis,
        'prescriptionRequired': prescriptionRequired,
      },
    );
  }
}

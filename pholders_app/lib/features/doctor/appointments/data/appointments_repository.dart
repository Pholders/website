import '../../../../core/network/api_client.dart';
import 'models/appointment.dart';

/// Doctor-side appointment calls.
class AppointmentsRepository {
  const AppointmentsRepository(this._api);

  final ApiClient _api;

  /// Fetches the doctor's appointments awaiting action.
  ///
  /// Note this is not the doctor's full diary: the backend filters to
  /// `status IN ('pending_payment', 'scheduled')` AND `doctor_accepted = false`.
  /// An appointment therefore disappears from this list as soon as it is
  /// accepted, and there is currently no endpoint that returns accepted or
  /// completed appointments for a doctor.
  Future<List<Appointment>> fetchPending({int limit = 50, int offset = 0}) async {
    final data = await _api.get(
      '/users/doctor/appointments',
      queryParameters: {'limit': limit, 'offset': offset},
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

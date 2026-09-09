import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/prescription.dart';

/// Doctor-side prescription calls.
///
/// Contracts verified against `controllers/prescriptionController.js` and the
/// live API — `docs/api/roles/DOCTOR_ENDPOINTS.md` is wrong about signing.
class PrescriptionsRepository {
  const PrescriptionsRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  /// Lists prescriptions issued by the signed-in doctor.
  ///
  /// [filter] accepts 'all', 'signed' or 'pending'; anything else is treated
  /// as 'all' by the backend. The rows carry no medicines.
  Future<List<Prescription>> fetchAll({
    String filter = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/prescriptions/doctor/all',
      queryParameters: {'filter': filter, 'limit': limit, 'offset': offset},
    );

    final list = data['prescriptions'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Prescription.fromJson)
        .toList();
  }

  /// Creates a prescription against one of the doctor's appointments.
  ///
  /// [appointmentId] is mandatory and must belong to this doctor — the
  /// backend has no way to issue a prescription outside a consultation, and
  /// rejects anything else with a 404.
  ///
  /// Returns the new prescription's id, ready for [addMedicine].
  Future<int> create({
    required int appointmentId,
    required String diagnosis,
    String? clinicalNotes,
  }) async {
    final data = await _api.post(
      '/prescriptions',
      body: {
        'appointmentId': appointmentId,
        'diagnosis': diagnosis,
        if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
      },
    );

    final id = data['id'] ?? data['prescriptionId'];
    final parsed = id is int ? id : int.tryParse('$id');
    if (parsed == null) {
      throw const ApiException(
        message: 'The prescription was created but no id came back.',
        kind: ApiErrorKind.badResponse,
      );
    }
    return parsed;
  }

  /// Adds one medicine to an unsigned prescription.
  ///
  /// Signed prescriptions are immutable — the backend returns 400 rather than
  /// letting a dispensed script change under the pharmacy's feet.
  Future<void> addMedicine({
    required int prescriptionId,
    required String medicineName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    int? quantity,
  }) async {
    await _api.post(
      '/prescriptions/$prescriptionId/medicines',
      body: {
        'medicine_name': medicineName,
        if (dosage != null) 'dosage': dosage,
        if (frequency != null) 'frequency': frequency,
        if (duration != null) 'duration': duration,
        if (instructions != null) 'instructions': instructions,
        if (quantity != null) 'quantity': quantity,
      },
    );
  }

  /// Checks the prescription's medicines against each other for interactions.
  Future<Map<String, dynamic>> checkInteractions(int prescriptionId) {
    return _api.post('/prescriptions/$prescriptionId/check-interactions');
  }

  /// Signs a prescription, making it valid and dispensable.
  ///
  /// Despite the docs, this takes no OTP. It wants the doctor's own JWT back
  /// as `sessionToken`: the backend SHA256-hashes it, matches it against the
  /// active session, and folds the session's device fingerprint and IP into
  /// the signature. So signing only works from the session that logged in.
  ///
  /// Fails with 400 if the prescription has no medicines yet.
  Future<void> sign(int prescriptionId) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Your session has expired. Please sign in again to sign prescriptions.',
        statusCode: 401,
        kind: ApiErrorKind.http,
      );
    }
    await _api.post(
      '/prescriptions/$prescriptionId/sign',
      body: {'sessionToken': token},
    );
  }

  /// Revokes a prescription so it can no longer be dispensed.
  Future<void> revoke(int prescriptionId, {String? reason}) async {
    await _api.post(
      '/prescriptions/$prescriptionId/revoke',
      body: {if (reason != null) 'reason': reason},
    );
  }
}

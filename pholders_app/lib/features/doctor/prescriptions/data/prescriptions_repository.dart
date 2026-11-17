import 'dart:typed_data';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/prescription.dart';
import 'models/safety_report.dart';
import 'models/signing_receipt.dart';

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
  ///
  /// [dosageForm] and [routeOfAdministration] are database enums, not free
  /// text, and both are required along with dosage, quantity and frequency.
  /// None of that is in the API docs; it comes from the prescription_items
  /// table definition, and omitting one fails with a not-null violation.
  Future<void> addMedicine({
    required int prescriptionId,
    required String medicineName,
    required String dosage,
    required MedicineDosageForm dosageForm,
    required int quantity,
    required String frequency,
    required MedicineRoute routeOfAdministration,
    String? genericName,
    String? quantityUnit,
    String? duration,
    String? specialInstructions,
    String? scheduleClassification,
  }) async {
    await _api.post(
      '/prescriptions/$prescriptionId/medicines',
      body: {
        'medicine_name': medicineName,
        'dosage': dosage,
        'dosage_form': dosageForm.name,
        'quantity': quantity,
        'frequency': frequency,
        'route_of_administration': routeOfAdministration.name,
        if (genericName != null) 'generic_name': genericName,
        if (quantityUnit != null) 'quantity_unit': quantityUnit,
        if (duration != null) 'duration': duration,
        // The column is special_instructions, not instructions.
        if (specialInstructions != null)
          'special_instructions': specialInstructions,
        if (scheduleClassification != null)
          'schedule_classification': scheduleClassification,
      },
    );
  }

  /// Checks the prescription's medicines against each other, and optionally
  /// against what else the patient is on.
  ///
  /// Worth running before signing: a signed prescription can no longer be
  /// edited, so a flagged interaction found afterwards can only be revoked.
  ///
  /// The backend defaults [patientAge] to 35 and [patientWeight] to 70 when
  /// they are not supplied, which is worth knowing before trusting a dosage
  /// review for a child or a frail patient.
  Future<SafetyReport> checkInteractions(
    int prescriptionId, {
    List<String> patientConditions = const [],
    List<String> currentMedications = const [],
    int? patientAge,
    int? patientWeight,
  }) async {
    final data = await _api.post(
      '/prescriptions/$prescriptionId/check-interactions',
      body: {
        'patientConditions': patientConditions,
        'currentMedications': currentMedications,
        if (patientAge != null) 'patientAge': patientAge,
        if (patientWeight != null) 'patientWeight': patientWeight,
      },
    );
    return SafetyReport.fromJson(data);
  }

  /// Signs a prescription, making it valid and dispensable.
  ///
  /// Despite the docs, this takes no OTP. It wants the doctor's own JWT back
  /// as `sessionToken`: the backend SHA256-hashes it, matches it against the
  /// active session, and folds the session's device fingerprint and IP into
  /// the signature. So signing only works from the session that logged in.
  ///
  /// Fails with 400 if the prescription has no medicines yet.
  ///
  /// Returns the signing receipt, which carries the QR payload and access
  /// link. They are generated here and nowhere else — no doctor endpoint
  /// returns them later — so the caller must show them before they are lost.
  Future<SigningReceipt> sign(int prescriptionId) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Your session has expired. Please sign in again to sign prescriptions.',
        statusCode: 401,
        kind: ApiErrorKind.http,
      );
    }
    final data = await _api.post(
      '/prescriptions/$prescriptionId/sign',
      body: {'sessionToken': token},
    );
    // The id is echoed in, so a server that omits it still yields a receipt
    // the UI can key on.
    return SigningReceipt.fromJson({'prescriptionId': prescriptionId, ...data});
  }

  /// Revokes a prescription so it can no longer be dispensed.
  ///
  /// The reason is mandatory and the field is `revokeReason` — sending
  /// `reason`, or omitting it, fails with 400. It is recorded against the
  /// prescription, which is the point of revoking rather than deleting.
  Future<void> revoke(int prescriptionId, {required String reason}) async {
    await _api.post(
      '/prescriptions/$prescriptionId/revoke',
      body: {'revokeReason': reason},
    );
  }

  /// The prescription as a PDF — the same document the patient receives.
  ///
  /// Both endpoints were patient-only until the prescriber was added to them,
  /// and each still refuses a prescription written by a different doctor.
  ///
  /// [forPrinting] asks for the inline copy. The bytes are identical; the
  /// difference is the disposition header, which only matters to a browser
  /// following the URL directly. Using both keeps the doctor on the same two
  /// endpoints the patient exercises, so neither can rot unnoticed.
  Future<Uint8List> fetchPdf(int prescriptionId, {bool forPrinting = false}) {
    return _api.getBytes(
      '/prescriptions/$prescriptionId/${forPrinting ? 'print' : 'download'}',
    );
  }
}

/// Dosage forms the backend accepts. Anything else violates the column check.
enum MedicineDosageForm {
  tablet,
  capsule,
  liquid,
  injection,
  cream,
  ointment,
  drops,
  spray,
  inhaler,
  patch,
  other,
}

/// Routes of administration the backend accepts.
enum MedicineRoute {
  oral,
  topical,
  intramuscular,
  intravenous,
  subcutaneous,
  inhalation,
  sublingual,
  rectal,
  other,
}

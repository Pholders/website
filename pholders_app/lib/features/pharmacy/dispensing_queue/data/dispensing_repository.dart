import '../../../../core/network/api_client.dart';
import 'models/claimed_prescription.dart';

/// Pharmacy-side dispensing calls.
///
/// Every route is guarded with `requireRole('pharmacy')`, so these only work
/// from a pharmacy session.
class DispensingRepository {
  const DispensingRepository(this._api);

  final ApiClient _api;

  /// Prescriptions patients have claimed here and not yet collected.
  ///
  /// A script reaches this list only when a patient sends it, which is why it
  /// stayed empty until the patient app could claim.
  Future<List<ClaimedPrescription>> fetchClaimed({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/prescriptions/pharmacy/claimed',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return _listFrom(data['prescriptions']);
  }

  /// What has already been handed over, newest first.
  Future<List<ClaimedPrescription>> fetchDispensed({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/prescriptions/pharmacy/dispense-history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    // The history endpoint names its list differently depending on the call.
    return _listFrom(data['prescriptions'] ?? data['history'] ?? data['data']);
  }

  /// The medicines on one claimed prescription.
  Future<List<DispensableMedicine>> fetchMedicines(int prescriptionId) async {
    final data = await _api.get('/prescriptions/pharmacy/medicines/$prescriptionId');
    final raw = data['medicines'] ?? data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DispensableMedicine.fromJson)
        .toList();
  }

  /// Hands the medicine over.
  ///
  /// The backend refuses this unless the script is claimed at *this* pharmacy
  /// and has not been dispensed already, so both come back as a message worth
  /// showing as-is.
  Future<void> dispense(int prescriptionId, {String? notes}) async {
    await _api.post(
      '/prescriptions/$prescriptionId/dispense',
      body: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
  }

  static List<ClaimedPrescription> _listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ClaimedPrescription.fromJson)
        .toList();
  }
}

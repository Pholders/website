import '../../../../core/network/api_client.dart';
import 'models/pharmacy_order.dart';

/// Pharmacy-side order calls.
///
/// Mirrors the backend state machine: a pharmacy accepts or rejects a new
/// order, then moves it along. It cannot skip states — the backend refuses an
/// invalid transition with a message worth showing as-is.
class OrdersRepository {
  const OrdersRepository(this._api);

  final ApiClient _api;

  /// Every order at this pharmacy, newest first.
  Future<List<PharmacyOrder>> fetchQueue({int limit = 50, int offset = 0}) async {
    final data = await _api.get(
      '/orders/pharmacy/queue',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final raw = data['orders'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PharmacyOrder.fromJson)
        .toList();
  }

  /// Takes the order on, optionally quoting it.
  ///
  /// A medical aid order can be accepted without a price: the claim decides
  /// what the patient owes.
  Future<void> accept(
    int orderId, {
    double? totalAmount,
    double? patientResponsibility,
    String? notes,
  }) async {
    await _api.patch(
      '/orders/$orderId/accept',
      body: {
        if (totalAmount != null) 'total_amount': totalAmount,
        if (patientResponsibility != null)
          'patient_responsibility': patientResponsibility,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// Declines it. The reason reaches the patient, so it is required here even
  /// though the backend tolerates its absence.
  Future<void> reject(int orderId, {required String reason}) async {
    await _api.patch('/orders/$orderId/reject', body: {'reason': reason});
  }

  /// Moves the order to its next state.
  Future<void> setStatus(
    int orderId, {
    required OrderStatus status,
    String? notes,
  }) async {
    await _api.patch(
      '/orders/$orderId/status',
      body: {
        'status': status.wireName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }
}

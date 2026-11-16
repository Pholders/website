import '../../../../core/network/api_client.dart';
import 'inventory_item.dart';

/// Which slice of stock to list.
enum InventoryFilter { all, lowStock, expiringSoon }

/// The days counted as "expiring soon", the backend's own default.
const expiringSoonDays = 30;

/// Pharmacy stock, saved on the server so it survives a refresh.
class InventoryRepository {
  const InventoryRepository(this._api);

  final ApiClient _api;

  Future<List<InventoryItem>> fetchItems({
    InventoryFilter filter = InventoryFilter.all,
    String? search,
  }) async {
    final data = await _api.get('/inventory', queryParameters: {
      'limit': 200,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (filter == InventoryFilter.lowStock) 'low_stock': 'true',
      if (filter == InventoryFilter.expiringSoon)
        'expiring_within_days': expiringSoonDays,
    });
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromJson)
        .toList();
  }

  Future<InventorySummary> fetchSummary() async {
    final data = await _api.get(
      '/inventory/meta/summary',
      queryParameters: {'expiring_within_days': expiringSoonDays},
    );
    return InventorySummary.fromJson(data);
  }

  /// Adds a new stock line. A starting quantity is logged as initial stock.
  Future<InventoryItem> create(Map<String, dynamic> fields) async {
    final data = await _api.post('/inventory', body: fields);
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  /// Changes the details. The backend ignores quantity here on purpose.
  Future<InventoryItem> update(int id, Map<String, dynamic> fields) async {
    final data = await _api.patch('/inventory/$id', body: fields);
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  /// Moves stock by [delta] and logs why.
  Future<InventoryItem> adjust(
    int id, {
    required int delta,
    required StockReason reason,
    String? notes,
  }) async {
    final data = await _api.post('/inventory/$id/adjust', body: {
      'delta': delta,
      'reason': reason.wireName,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  /// Takes the line off the list. The backend keeps it, marked inactive, so
  /// its adjustment history is not lost.
  Future<void> remove(int id) async {
    await _api.delete('/inventory/$id');
  }
}

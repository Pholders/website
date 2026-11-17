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

  Future<InventoryPageResult> fetchItems({
    InventoryFilter filter = InventoryFilter.all,
    String? search,
    bool lowStock = false,
    int? expiringWithinDays,
    bool includeInactive = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/inventory',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (lowStock || filter == InventoryFilter.lowStock) 'low_stock': true,
        if (expiringWithinDays != null)
          'expiring_within_days': expiringWithinDays,
        if (filter == InventoryFilter.expiringSoon &&
            expiringWithinDays == null)
          'expiring_within_days': expiringSoonDays,
        if (includeInactive) 'include_inactive': true,
      },
    );
    final raw = data['items'];
    final items = raw is! List
        ? const <InventoryItem>[]
        : raw
            .whereType<Map<String, dynamic>>()
            .map(InventoryItem.fromJson)
            .toList();
    final pagination = data['pagination'];
    final page = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};
    return InventoryPageResult(
      items: items,
      total: _int(page['total']) ?? items.length,
      limit: _int(page['limit']) ?? limit,
      offset: _int(page['offset']) ?? offset,
    );
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

  Future<InventoryItem> createItem(Map<String, dynamic> fields) =>
      create(fields);

  /// Changes the details. The backend ignores quantity here on purpose.
  Future<InventoryItem> update(int id, Map<String, dynamic> fields) async {
    final data = await _api.patch('/inventory/$id', body: fields);
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<InventoryItem> updateItem(
    String id,
    Map<String, dynamic> fields,
  ) async {
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

  Future<InventoryItem> adjustQuantity(
    String id, {
    required int delta,
    required String reason,
    String? notes,
  }) async {
    final data = await _api.post('/inventory/$id/adjust', body: {
      'delta': delta,
      'reason': reason,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchAdjustments(String id) async {
    final data = await _api.get('/inventory/$id/adjustments');
    final raw = data['adjustments'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  /// Takes the line off the list. The backend keeps it, marked inactive, so
  /// its adjustment history is not lost.
  Future<void> remove(int id) async {
    await _api.delete('/inventory/$id');
  }

  Future<InventoryItem> deactivateItem(String id) async {
    final data = await _api.delete('/inventory/$id');
    return InventoryItem.fromJson(data['item'] as Map<String, dynamic>);
  }
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

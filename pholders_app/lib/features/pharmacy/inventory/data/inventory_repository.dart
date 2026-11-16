import '../../../../core/network/api_client.dart';
import '../domain/inventory_item.dart';

class InventoryRepository {
  const InventoryRepository(this._api);

  final ApiClient _api;

  Future<InventoryPageResult> fetchItems({
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
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (lowStock) 'low_stock': true,
        if (expiringWithinDays != null)
          'expiring_within_days': expiringWithinDays,
        if (includeInactive) 'include_inactive': true,
        'limit': limit,
        'offset': offset,
      },
    );
    final pagination = _map(data['pagination']);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => InventoryItem.fromJson(_map(item)))
            .toList(growable: false)
        : const <InventoryItem>[];

    return InventoryPageResult(
      items: items,
      total: _int(pagination['total'], fallback: items.length),
      limit: _int(pagination['limit'], fallback: limit),
      offset: _int(pagination['offset'], fallback: offset),
    );
  }

  Future<InventorySummary> fetchSummary({int expiringWithinDays = 30}) async {
    final data = await _api.get(
      '/inventory/meta/summary',
      queryParameters: {'expiring_within_days': expiringWithinDays},
    );
    return InventorySummary.fromJson(data);
  }

  Future<InventoryItem> fetchItem(String id) async {
    final data = await _api.get('/inventory/$id');
    return InventoryItem.fromJson(_map(data['item']));
  }

  Future<InventoryItem> createItem(Map<String, dynamic> body) async {
    final data = await _api.post('/inventory', body: body);
    return InventoryItem.fromJson(_map(data['item']));
  }

  Future<InventoryItem> updateItem(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.patch('/inventory/$id', body: body);
    return InventoryItem.fromJson(_map(data['item']));
  }

  Future<InventoryItem> adjustQuantity(
    String id, {
    required int delta,
    required String reason,
    String? notes,
  }) async {
    final data = await _api.post(
      '/inventory/$id/adjust',
      body: {
        'delta': delta,
        'reason': reason,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return InventoryItem.fromJson(_map(data['item']));
  }

  Future<List<Map<String, dynamic>>> fetchAdjustments(
    String id, {
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/inventory/$id/adjustments',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final adjustments = data['adjustments'];
    if (adjustments is! List) return const [];
    return adjustments.whereType<Map>().map(_map).toList(growable: false);
  }

  Future<InventoryItem> deactivateItem(String id) async {
    final data = await _api.delete('/inventory/$id');
    return InventoryItem.fromJson(_map(data['item']));
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

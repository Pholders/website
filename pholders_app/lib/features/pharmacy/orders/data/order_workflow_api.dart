import 'package:dio/dio.dart';

typedef OrderJson = Map<String, dynamic>;

class OrderPageResult {
  const OrderPageResult({
    required this.orders,
    required this.limit,
    required this.offset,
    required this.total,
  });

  final List<OrderJson> orders;
  final int limit;
  final int offset;
  final int total;
}

class OrderWorkflowApi {
  const OrderWorkflowApi(this._dio);

  final Dio _dio;

  Future<OrderJson> fetchStatuses() async {
    final response = await _dio.get<dynamic>('orders/meta/statuses');
    return _dataMap(response.data);
  }

  Future<OrderPageResult> fetchPharmacyQueue({
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      'orders/pharmacy/queue',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    final data = _dataMap(response.data);
    final pagination = _map(data['pagination']);
    return OrderPageResult(
      orders: _mapList(data['orders']),
      limit: _intValue(pagination['limit'], limit),
      offset: _intValue(pagination['offset'], offset),
      total: _intValue(pagination['total'], 0),
    );
  }

  Future<OrderPageResult> fetchPatientOrders({
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      'orders',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    final data = _dataMap(response.data);
    final pagination = _map(data['pagination']);
    return OrderPageResult(
      orders: _mapList(data['orders']),
      limit: _intValue(pagination['limit'], limit),
      offset: _intValue(pagination['offset'], offset),
      total: _intValue(pagination['total'], 0),
    );
  }

  Future<OrderJson> fetchOrder(String orderId) async {
    final response = await _dio.get<dynamic>('orders/$orderId');
    return _dataMap(response.data);
  }

  /// POST /orders is authorized for patient tokens only.
  Future<OrderJson> createPatientOrder({
    required int prescriptionId,
    required int pharmacyId,
    required String paymentType,
  }) async {
    final response = await _dio.post<dynamic>(
      'orders',
      data: {
        'prescription_id': prescriptionId,
        'pharmacy_id': pharmacyId,
        'payment_type': paymentType,
      },
    );
    return _dataMap(response.data);
  }

  Future<OrderJson> acceptOrder(
    String orderId, {
    required num totalAmount,
    String? notes,
  }) async {
    final response = await _dio.patch<dynamic>(
      'orders/$orderId/accept',
      data: {
        'total_amount': totalAmount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return _dataMap(response.data);
  }

  Future<OrderJson> updateStatus(String orderId, String status) async {
    final response = await _dio.patch<dynamic>(
      'orders/$orderId/status',
      data: {'status': status},
    );
    return _dataMap(response.data);
  }

  Future<OrderJson> rejectOrder(String orderId, String reason) async {
    final response = await _dio.patch<dynamic>(
      'orders/$orderId/reject',
      data: {'reason': reason},
    );
    return _dataMap(response.data);
  }

  Future<OrderJson> fetchDispenseSuggestions(String orderId) async {
    final response = await _dio.get<dynamic>(
      'orders/$orderId/dispense-suggestions',
    );
    return _dataMap(response.data);
  }

  Future<OrderJson> dispenseItems(
    String orderId,
    List<OrderJson> items,
  ) async {
    final response = await _dio.post<dynamic>(
      'orders/$orderId/dispense-items',
      data: {'items': items},
    );
    return _dataMap(response.data);
  }
}

OrderJson _dataMap(dynamic value) {
  final response = _map(value);
  return _map(response['data']).isNotEmpty ? _map(response['data']) : response;
}

OrderJson _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<OrderJson> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_map).toList(growable: false);
}

int _intValue(dynamic value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

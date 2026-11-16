import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/pharmacy/inventory/data/inventory_repository.dart';

class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.routes);

  final Map<String, Map<String, dynamic>> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Map<String, dynamic> body =
        routes['${options.method} ${options.path}'] ??
            {
              'success': false,
              'message': 'No test route for ${options.method} ${options.path}',
            };
    final status = body['success'] == true ? 200 : 404;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('parses inventory decimals and sends documented stock requests',
      () async {
    final server = _Server({
      'GET /inventory': {
        'success': true,
        'data': {
          'items': [
            {
              'id': 5,
              'sku': 'PARA-500',
              'medication_name': 'Paracetamol',
              'generic_name': 'Paracetamol',
              'dosage': '500mg tablet',
              'unit': 'tablets',
              'quantity_on_hand': 100,
              'low_stock_threshold': 20,
              'unit_price': '2.50',
              'is_active': true,
            },
          ],
          'pagination': {'total': 1, 'limit': 50, 'offset': 0, 'returned': 1},
        },
      },
      'GET /inventory/meta/summary': {
        'success': true,
        'data': {
          'totalActive': 1,
          'lowStock': 0,
          'outOfStock': 0,
          'expiringSoon': 0,
          'expired': 0,
          'expiringWithinDays': 30,
        },
      },
      'POST /inventory': {
        'success': true,
        'data': {
          'item': {
            'id': 5,
            'medication_name': 'Paracetamol',
            'quantity_on_hand': 0,
            'low_stock_threshold': 0,
            'is_active': true,
          },
        },
      },
      'PATCH /inventory/5': {
        'success': true,
        'data': {
          'item': {
            'id': 5,
            'medication_name': 'Paracetamol',
            'quantity_on_hand': 100,
            'low_stock_threshold': 20,
            'is_active': true,
          },
        },
      },
      'POST /inventory/5/adjust': {
        'success': true,
        'data': {
          'item': {
            'id': 5,
            'medication_name': 'Paracetamol',
            'quantity_on_hand': 125,
            'low_stock_threshold': 20,
            'is_active': true,
          },
          'adjustment': {'delta': 25, 'reason': 'restock'},
        },
      },
      'GET /inventory/5/adjustments': {
        'success': true,
        'data': {
          'adjustments': [
            {'delta': 25, 'reason': 'restock', 'notes': 'Supplier delivery'},
          ],
        },
      },
      'DELETE /inventory/5': {
        'success': true,
        'data': {
          'item': {
            'id': 5,
            'medication_name': 'Paracetamol',
            'quantity_on_hand': 125,
            'low_stock_threshold': 20,
            'is_active': false,
          },
        },
      },
    });
    final repository = InventoryRepository(
      ApiClient(
          tokenStorage: const _NoSession(),
          dio: Dio()..httpClientAdapter = server),
    );

    final page = await repository.fetchItems(
      search: ' para ',
      lowStock: true,
      expiringWithinDays: 30,
      includeInactive: true,
    );
    final summary = await repository.fetchSummary();
    final created = await repository.createItem({
      'medication_name': 'Paracetamol',
      'quantity_on_hand': 0,
    });
    final updated = await repository.updateItem('5', {'supplier': 'Supplier'});
    final adjusted = await repository.adjustQuantity(
      '5',
      delta: 25,
      reason: 'restock',
      notes: 'Supplier delivery',
    );
    final history = await repository.fetchAdjustments('5');
    final deactivated = await repository.deactivateItem('5');

    expect(page.total, 1);
    expect(page.items.single.medicationName, 'Paracetamol');
    expect(page.items.single.unitPrice, 2.5);
    expect(page.items.single.quantityOnHand, 100);
    expect(summary.totalActive, 1);
    expect(created.medicationName, 'Paracetamol');
    expect(updated.medicationName, 'Paracetamol');
    expect(adjusted.quantityOnHand, 125);
    expect(history.single['reason'], 'restock');
    expect(deactivated.isActive, isFalse);
    expect(server.requests[0].queryParameters, {
      'search': 'para',
      'low_stock': true,
      'expiring_within_days': 30,
      'include_inactive': true,
      'limit': 50,
      'offset': 0,
    });
    expect(server.requests[2].data, {
      'medication_name': 'Paracetamol',
      'quantity_on_hand': 0,
    });
    expect(server.requests[3].data, {'supplier': 'Supplier'});
    expect(server.requests[4].data, {
      'delta': 25,
      'reason': 'restock',
      'notes': 'Supplier delivery',
    });
  });
}

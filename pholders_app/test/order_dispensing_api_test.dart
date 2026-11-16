import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/pharmacy/orders/data/order_workflow_api.dart';

class _Server implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'dispensed': true}
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('order item dispense submits inventory matches, quantities, and notes',
      () async {
    final server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example/api/'))
      ..httpClientAdapter = server;
    final api = OrderWorkflowApi(dio);

    await api.dispenseItems(
      '42',
      [
        {
          'prescription_item_id': 3,
          'inventory_item_id': 8,
          'quantity': 14,
        },
      ],
      notes: 'Partial supply',
    );

    expect(server.request?.method, 'POST');
    expect(server.request?.uri.path, '/api/orders/42/dispense-items');
    expect(server.request?.data, {
      'items': [
        {
          'prescription_item_id': 3,
          'inventory_item_id': 8,
          'quantity': 14,
        },
      ],
      'notes': 'Partial supply',
    });
  });
}

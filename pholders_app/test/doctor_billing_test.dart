import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/billing/data/billing_repository.dart';
import 'package:pholders_app/features/doctor/billing/presentation/billing_page.dart';

/// Billing shows the doctor's real payments. It used to show seven invented
/// transactions, an R88,200 "Total Earnings", and a Withdraw button that
/// announced a payout nobody made.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.routes);

  /// "METHOD /path" → (status, body)
  final Map<String, (int, Object)> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final (status, body) = routes[key] ?? (404, {'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

const _summary = {
  'success': true,
  'data': {
    'totalPayments': 4,
    'completedPayments': 2,
    'completedAmount': 9900,
    'pendingPayments': 1,
    'pendingAmount': '1350.00',
    'failedPayments': 0,
    'cancelledPayments': 1,
    'currency': 'ZAR',
  },
};

Map<String, Object?> _payment(int id, String name, String status, String method, String amount) => {
      'paymentId': id,
      'appointmentId': id + 10,
      'patientName': name,
      'service': 'consultation',
      'appointmentDate': '2026-10-29T00:00:00.000Z',
      'amount': amount,
      'paymentMethod': method,
      'paymentStatus': status,
    };

final _payments = {
  'success': true,
  'data': {
    'payments': [
      _payment(58, 'Naledi Khumalo', 'completed', 'cash_on_arrival', '450.00'),
      _payment(57, 'Sipho Dube', 'pending', 'stripe', '1350.00'),
      _payment(56, 'Ayanda Zulu', 'cancelled', 'stripe', '450.00'),
    ],
    'pagination': {'total': 3},
  },
};

void main() {
  Future<void> show(WidgetTester tester, Map<String, (int, Object)> routes) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = ApiClient(
        tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = _Server(routes));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BillingPage(repository: BillingRepository(api))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the real totals and payments, none of the invented ones', (tester) async {
    await show(tester, {
      'GET /users/doctor/payments/summary': (200, _summary),
      'GET /users/doctor/payments': (200, _payments),
    });

    expect(find.text('R9,900'), findsOneWidget);
    expect(find.text('R1,350'), findsNWidgets(2), reason: 'pending total and the row');
    expect(find.text('Naledi Khumalo'), findsOneWidget);
    expect(find.text('29 Oct 2026'), findsNWidgets(3));
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);

    expect(find.text('R88,200'), findsNothing);
    expect(find.text('Maria Wilson'), findsNothing);
    expect(find.text('Withdraw Funds'), findsNothing);
  });

  testWidgets('the row menu offers no cancel, and the receipt says how they paid', (tester) async {
    await show(tester, {
      'GET /users/doctor/payments/summary': (200, _summary),
      'GET /users/doctor/payments': (200, _payments),
    });

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Cancel Transaction'), findsNothing);

    await tester.tap(find.text('Download Receipt'));
    await tester.pumpAndSettle();
    expect(find.text('PAY-58'), findsOneWidget);
    expect(find.text('Cash at the practice'), findsOneWidget);
  });

  testWidgets('search narrows the list and says when nothing matches', (tester) async {
    await show(tester, {
      'GET /users/doctor/payments/summary': (200, _summary),
      'GET /users/doctor/payments': (200, _payments),
    });

    await tester.enterText(find.byType(TextField), 'card');
    await tester.pumpAndSettle();
    expect(find.text('Sipho Dube'), findsOneWidget);
    expect(find.text('Naledi Khumalo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No transactions found'), findsOneWidget);
  });

  testWidgets('a doctor with no payments is told so, not shown a search miss', (tester) async {
    await show(tester, {
      'GET /users/doctor/payments/summary': (200, {'success': true, 'data': <String, Object>{}}),
      'GET /users/doctor/payments': (200, {'success': true, 'data': {'payments': <Object>[]}}),
    });

    expect(find.text('No payments yet'), findsOneWidget);
    expect(find.text('R0'), findsNWidgets(2));
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    await show(tester, {
      'GET /users/doctor/payments/summary': (500, {'success': false, 'message': 'Server error'}),
      'GET /users/doctor/payments': (200, _payments),
    });

    expect(find.text('Could not load your payments'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  // The portal's pages sit inside a ShellRoute, so they have their own
  // Navigator while dialogs open on the root one. Closing a dialog with the
  // page's context popped the page instead, and crashed.
  Future<void> showInShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = ApiClient(
        tokenStorage: const _NoSession(),
        dio: Dio()
          ..httpClientAdapter = _Server({
            'GET /users/doctor/payments/summary': (200, _summary),
            'GET /users/doctor/payments': (200, _payments),
          }));
    final router = GoRouter(initialLocation: '/billing', routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/billing',
            builder: (context, state) => BillingPage(repository: BillingRepository(api)),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> openFromMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('closing View Details closes only the dialog', (tester) async {
    await showInShell(tester);
    await openFromMenu(tester, 'View Details');
    expect(find.text('Transaction Details'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Transaction Details'), findsNothing);
    expect(find.text('Billing & Payments'), findsOneWidget);
  });

  testWidgets('Receipt from the details opens the receipt, and Close keeps the page', (tester) async {
    await showInShell(tester);
    await openFromMenu(tester, 'View Details');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Details'), findsNothing);
    expect(find.text('Payment Receipt'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Payment Receipt'), findsNothing);
    expect(find.text('Billing & Payments'), findsOneWidget);
  });

  test('rand amounts are grouped by thousands and keep real cents', () {
    expect(formatRand(9900), 'R9,900');
    expect(formatRand(1234567), 'R1,234,567');
    expect(formatRand(450.5), 'R450.50');
    expect(formatRand(0), 'R0');
  });
}

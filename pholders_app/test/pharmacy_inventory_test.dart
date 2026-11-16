import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/pharmacy/inventory/data/inventory_item.dart';
import 'package:pholders_app/features/pharmacy/inventory/data/inventory_repository.dart';
import 'package:pholders_app/features/pharmacy/inventory/presentation/inventory_page.dart';

/// Stands in for the server: keeps stock in a list, so a reload after a
/// save shows what was saved, as the real one does.
class _FakeRepo implements InventoryRepository {
  _FakeRepo(this.rows);

  final List<Map<String, dynamic>> rows;
  final created = <Map<String, dynamic>>[];
  final adjusted = <(int, int, StockReason)>[];
  final removed = <int>[];
  final filters = <InventoryFilter>[];
  Object? failWith;

  @override
  Future<List<InventoryItem>> fetchItems({
    InventoryFilter filter = InventoryFilter.all,
    String? search,
  }) async {
    filters.add(filter);
    if (failWith != null) throw failWith!;
    final items = rows.map(InventoryItem.fromJson).toList();
    return switch (filter) {
      InventoryFilter.lowStock => items.where((i) => i.isLowStock).toList(),
      _ => items,
    };
  }

  @override
  Future<InventorySummary> fetchSummary() async {
    if (failWith != null) throw failWith!;
    final items = rows.map(InventoryItem.fromJson).toList();
    return InventorySummary(
      totalActive: items.length,
      lowStock: items.where((i) => i.isLowStock).length,
      outOfStock: items.where((i) => i.isOutOfStock).length,
      expiringSoon: 0,
      expired: 0,
    );
  }

  @override
  Future<InventoryItem> create(Map<String, dynamic> fields) async {
    created.add(fields);
    final row = {
      ...fields,
      'id': 100 + created.length,
      'quantity_on_hand': fields['quantity_on_hand'] ?? 0,
    };
    rows.add(row);
    return InventoryItem.fromJson(row);
  }

  @override
  Future<InventoryItem> update(int id, Map<String, dynamic> fields) async {
    final row = rows.firstWhere((r) => r['id'] == id);
    row.addAll(fields);
    return InventoryItem.fromJson(row);
  }

  @override
  Future<InventoryItem> adjust(
    int id, {
    required int delta,
    required StockReason reason,
    String? notes,
  }) async {
    adjusted.add((id, delta, reason));
    final row = rows.firstWhere((r) => r['id'] == id);
    row['quantity_on_hand'] = (row['quantity_on_hand'] as int) + delta;
    return InventoryItem.fromJson(row);
  }

  @override
  Future<void> remove(int id) async {
    removed.add(id);
    rows.removeWhere((r) => r['id'] == id);
  }
}

Map<String, dynamic> _row({
  required int id,
  required String name,
  int onHand = 50,
  int lowAt = 10,
  String? dosage,
  String? price,
  String? expiry,
}) =>
    {
      'id': id,
      'medication_name': name,
      'quantity_on_hand': onHand,
      'low_stock_threshold': lowAt,
      'dosage': dosage,
      'unit_price': price,
      'expiry_date': expiry,
      'unit': 'tablets',
    };

Future<void> _show(WidgetTester tester, _FakeRepo repo) async {
  tester.view.physicalSize = const Size(1500, 950);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: InventoryPage(repository: repo, today: DateTime(2026, 11, 13)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('reading what the server sends', () {
    test('a decimal price and a DATE column read as they were stored', () {
      final item = InventoryItem.fromJson(_row(
        id: 1,
        name: 'Amoxicillin',
        price: '45.50',
        // Postgres DATE through JSON: midnight UTC. It must stay the 31st.
        expiry: '2027-01-31T00:00:00.000Z',
      ));
      expect(item.unitPrice, 45.5);
      expect(item.expiryDate, DateTime(2027, 1, 31));
    });

    test('at the threshold is low, and none at all is out', () {
      expect(InventoryItem.fromJson(_row(id: 1, name: 'A', onHand: 10)).isLowStock,
          isTrue);
      expect(InventoryItem.fromJson(_row(id: 1, name: 'A', onHand: 11)).isLowStock,
          isFalse);
      expect(InventoryItem.fromJson(_row(id: 1, name: 'A', onHand: 0)).isOutOfStock,
          isTrue);
    });

    test('expiring soon means within the window and not already expired', () {
      final today = DateTime(2026, 11, 13);
      InventoryItem expiring(String day) =>
          InventoryItem.fromJson(_row(id: 1, name: 'A', expiry: day));
      expect(expiring('2026-12-01').expiresWithin(30, today), isTrue);
      expect(expiring('2027-03-01').expiresWithin(30, today), isFalse);
      expect(expiring('2026-11-01').isExpired(today), isTrue);
      expect(expiring('2026-11-01').expiresWithin(30, today), isFalse);
    });

    test('rand amounts read the South African way', () {
      expect(formatRand(1250), 'R 1 250.00');
      expect(formatRand(45.5), 'R 45.50');
    });
  });

  testWidgets('the stock on the server is what the table shows', (tester) async {
    final repo = _FakeRepo([
      _row(id: 1, name: 'Amoxicillin', dosage: '500mg capsule', price: '45.50'),
      _row(id: 2, name: 'Paracetamol', onHand: 4),
      _row(id: 3, name: 'Ibuprofen', onHand: 0),
    ]);
    await _show(tester, repo);

    expect(find.text('Amoxicillin'), findsOneWidget);
    expect(find.text('500mg capsule'), findsOneWidget);
    expect(find.text('R 45.50'), findsOneWidget);
    expect(find.text('Low stock'), findsWidgets);
    expect(find.text('Out of stock'), findsWidgets);
    // None of the copied order rows the page used to show.
    expect(find.text('Prince Mashumu'), findsNothing);
    expect(find.text('Mark Ready'), findsNothing);
  });

  testWidgets('with nothing in stock it says how to start', (tester) async {
    await _show(tester, _FakeRepo([]));
    expect(find.textContaining('No stock yet'), findsOneWidget);
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    final repo = _FakeRepo([_row(id: 1, name: 'Amoxicillin')])
      ..failWith = const ApiException(message: 'The server is waking up');
    await _show(tester, repo);
    expect(find.text('The server is waking up'), findsOneWidget);

    repo.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Amoxicillin'), findsOneWidget);
  });

  testWidgets('the low stock tab asks the server for low stock', (tester) async {
    final repo = _FakeRepo([
      _row(id: 1, name: 'Amoxicillin'),
      _row(id: 2, name: 'Paracetamol', onHand: 4),
    ]);
    await _show(tester, repo);
    await tester.tap(find.byKey(const ValueKey('inventory-tab-lowStock')));
    await tester.pumpAndSettle();

    expect(repo.filters.last, InventoryFilter.lowStock);
    expect(find.text('Amoxicillin'), findsNothing);
    expect(find.text('Paracetamol'), findsOneWidget);
  });

  testWidgets('an added item is sent to the server and stays listed',
      (tester) async {
    final repo = _FakeRepo([]);
    await _show(tester, repo);

    await tester.tap(find.byKey(const ValueKey('inventory-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('inventory-field-name')), 'Metformin');
    await tester.enterText(
        find.byKey(const ValueKey('inventory-field-quantity')), '120');
    await tester.enterText(
        find.byKey(const ValueKey('inventory-field-threshold')), '20');
    await tester.tap(find.byKey(const ValueKey('inventory-save')));
    await tester.pumpAndSettle();

    expect(repo.created.single['medication_name'], 'Metformin');
    expect(repo.created.single['quantity_on_hand'], 120);
    expect(repo.created.single['low_stock_threshold'], 20);
    // Reloaded from the server, not just drawn from the form.
    expect(find.byKey(const ValueKey('inventory-row-101')), findsOneWidget);
  });

  testWidgets('a nameless item is not sent', (tester) async {
    final repo = _FakeRepo([]);
    await _show(tester, repo);
    await tester.tap(find.byKey(const ValueKey('inventory-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inventory-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the medication name'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('a restock adds to what is on hand', (tester) async {
    final repo = _FakeRepo([_row(id: 1, name: 'Amoxicillin', onHand: 50)]);
    await _show(tester, repo);

    await tester.tap(find.byKey(const ValueKey('inventory-adjust-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('inventory-amount')), '25');
    await tester.pump();
    expect(find.text('On hand: 50 → 75'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('inventory-adjust-save')));
    await tester.pumpAndSettle();

    expect(repo.adjusted.single, (1, 25, StockReason.restock));
    expect(find.text('75 tablets'), findsOneWidget);
  });

  testWidgets('removing more than is on hand is stopped before sending',
      (tester) async {
    final repo = _FakeRepo([_row(id: 1, name: 'Amoxicillin', onHand: 3)]);
    await _show(tester, repo);

    await tester.tap(find.byKey(const ValueKey('inventory-adjust-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inventory-reason')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('inventory-amount')), '5');
    await tester.tap(find.byKey(const ValueKey('inventory-adjust-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Only 3 on hand'), findsOneWidget);
    expect(repo.adjusted, isEmpty);
  });

  testWidgets('remove asks first, then takes the item off', (tester) async {
    final repo = _FakeRepo([_row(id: 1, name: 'Amoxicillin')]);
    await _show(tester, repo);

    await tester.tap(find.byKey(const ValueKey('inventory-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(find.text('Remove Amoxicillin?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(repo.removed, [1]);
    expect(find.byKey(const ValueKey('inventory-row-1')), findsNothing);
  });
}

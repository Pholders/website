/// One stock line at this pharmacy, as `/api/inventory` returns it.
///
/// Quantity is never edited directly: it only moves through an adjustment
/// (restock, damaged, correction and so on), which the backend logs so the
/// pharmacy can always see why stock changed.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.medicationName,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    this.sku,
    this.genericName,
    this.dosage,
    this.packSize,
    this.unit,
    this.unitPrice,
    this.expiryDate,
    this.supplier,
    this.notes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: _int(json['id']) ?? 0,
      medicationName: (json['medication_name'] as String?)?.trim() ?? '',
      quantityOnHand: _int(json['quantity_on_hand']) ?? 0,
      lowStockThreshold: _int(json['low_stock_threshold']) ?? 0,
      sku: _text(json['sku']),
      genericName: _text(json['generic_name']),
      dosage: _text(json['dosage']),
      packSize: _int(json['pack_size']),
      unit: _text(json['unit']),
      // Postgres DECIMAL arrives as a string ("450.00").
      unitPrice: _double(json['unit_price']),
      expiryDate: _day(json['expiry_date']),
      supplier: _text(json['supplier']),
      notes: _text(json['notes']),
    );
  }

  final int id;
  final String medicationName;
  final int quantityOnHand;
  final int lowStockThreshold;
  final String? sku;
  final String? genericName;
  final String? dosage;
  final int? packSize;
  final String? unit;
  final double? unitPrice;
  final DateTime? expiryDate;
  final String? supplier;
  final String? notes;

  bool get isOutOfStock => quantityOnHand == 0;

  /// The backend's own rule: at or below the threshold counts as low.
  bool get isLowStock => quantityOnHand <= lowStockThreshold;

  bool isExpired(DateTime today) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return expiry.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Expires within [days] of today, and has not expired yet.
  bool expiresWithin(int days, DateTime today) {
    final expiry = expiryDate;
    if (expiry == null || isExpired(today)) return false;
    final limit = DateTime(today.year, today.month, today.day + days);
    return !expiry.isAfter(limit);
  }
}

/// The counts above the table, from `/api/inventory/meta/summary`.
class InventorySummary {
  const InventorySummary({
    required this.totalActive,
    required this.lowStock,
    required this.outOfStock,
    required this.expiringSoon,
    required this.expired,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalActive: _int(json['totalActive']) ?? 0,
      lowStock: _int(json['lowStock']) ?? 0,
      outOfStock: _int(json['outOfStock']) ?? 0,
      expiringSoon: _int(json['expiringSoon']) ?? 0,
      expired: _int(json['expired']) ?? 0,
    );
  }

  final int totalActive;
  final int lowStock;
  final int outOfStock;
  final int expiringSoon;
  final int expired;
}

/// Why stock moved. Only the reasons a person chooses by hand: `dispense`
/// is written by the order flow and `initial_stock` by creating the item.
enum StockReason {
  restock('restock', 'Restock (delivery received)', 1),
  returned('return', 'Returned by patient', 1),
  correction('correction', 'Stock count correction', 0),
  manualAdjust('manual_adjust', 'Other adjustment', 0),
  damaged('damaged', 'Damaged', -1),
  expired('expired', 'Expired', -1);

  const StockReason(this.wireName, this.label, this.direction);

  final String wireName;
  final String label;

  /// 1 adds stock, -1 removes it, 0 either way.
  final int direction;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// A DATE column, kept as the calendar day it names. Only the date part is
/// read, so a timezone on the wire cannot move it to the day before.
DateTime? _day(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.medicationName,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.isActive,
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
      id: _string(json['id']) ?? '',
      sku: _string(json['sku']),
      medicationName: _string(json['medication_name']) ?? 'Unnamed medication',
      genericName: _string(json['generic_name']),
      dosage: _string(json['dosage']),
      packSize: _string(json['pack_size']),
      unit: _string(json['unit']),
      quantityOnHand: _int(json['quantity_on_hand']) ?? 0,
      lowStockThreshold: _int(json['low_stock_threshold']) ?? 0,
      unitPrice: _double(json['unit_price']),
      expiryDate: DateTime.tryParse(_string(json['expiry_date']) ?? ''),
      supplier: _string(json['supplier']),
      notes: _string(json['notes']),
      isActive: json['is_active'] != false && json['is_active'] != 0,
    );
  }

  final String id;
  final String? sku;
  final String medicationName;
  final String? genericName;
  final String? dosage;
  final String? packSize;
  final String? unit;
  final int quantityOnHand;
  final int lowStockThreshold;
  final double? unitPrice;
  final DateTime? expiryDate;
  final String? supplier;
  final String? notes;
  final bool isActive;

  bool get isOutOfStock => quantityOnHand == 0;
  bool get isLowStock =>
      quantityOnHand > 0 && quantityOnHand <= lowStockThreshold;

  String get stockStatus {
    if (!isActive) return 'Inactive';
    if (expiryDate != null && expiryDate!.isBefore(DateTime.now())) {
      return 'Expired';
    }
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low stock';
    return 'In stock';
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class InventorySummary {
  const InventorySummary({
    this.totalActive = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
    this.expiringSoon = 0,
    this.expired = 0,
    this.expiringWithinDays = 30,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalActive: _readInt(json['totalActive']),
      lowStock: _readInt(json['lowStock']),
      outOfStock: _readInt(json['outOfStock']),
      expiringSoon: _readInt(json['expiringSoon']),
      expired: _readInt(json['expired']),
      expiringWithinDays: _readInt(json['expiringWithinDays'], fallback: 30),
    );
  }

  final int totalActive;
  final int lowStock;
  final int outOfStock;
  final int expiringSoon;
  final int expired;
  final int expiringWithinDays;

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class InventoryPageResult {
  const InventoryPageResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<InventoryItem> items;
  final int total;
  final int limit;
  final int offset;
}

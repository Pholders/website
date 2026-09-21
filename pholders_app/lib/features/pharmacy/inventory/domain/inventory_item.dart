class InventoryItem {

  InventoryItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.nappiCode,
  });
  final String name;
  final String category;
  final String nappiCode;
  int quantity;
  final int reorderLevel;

  bool get isOutOfStock => quantity == 0;

  bool get isLowStock => quantity > 0 && quantity <= reorderLevel;

  bool get isInStock => quantity > reorderLevel;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  String get patientAvailabilityLabel {
    if (isOutOfStock) return 'Unavailable';
    if (isLowStock) return 'Limited';
    return 'Available';
  }

  String get patientAvailabilityHint {
    if (isOutOfStock) {
      return 'Ask the pharmacy to confirm the next restock window.';
    }
    if (isLowStock) {
      return 'Stock is running low and may change quickly.';
    }
    return 'Usually ready for dispensing when prescribed.';
  }
}

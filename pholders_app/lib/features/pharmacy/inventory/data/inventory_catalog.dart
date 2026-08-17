import '../domain/inventory_item.dart';

class InventoryCatalog {
  InventoryCatalog._();

  static final List<InventoryItem> items = [
    InventoryItem(name: 'Panado 500mg', category: 'Analgesic', quantity: 245, reorderLevel: 50, nappiCode: '710801001'),
    InventoryItem(name: 'Isotretinoin 20mg', category: 'Dermatology', quantity: 12, reorderLevel: 30, nappiCode: '703200041'),
    InventoryItem(name: 'Amoxicillin 500mg', category: 'Antibiotic', quantity: 0, reorderLevel: 40, nappiCode: '706500012'),
    InventoryItem(name: 'Metformin 850mg', category: 'Diabetes', quantity: 89, reorderLevel: 60, nappiCode: '708100023'),
    InventoryItem(name: 'Atorvastatin 20mg', category: 'Cholesterol', quantity: 22, reorderLevel: 30, nappiCode: '709400034'),
    InventoryItem(name: 'Omeprazole 20mg', category: 'GI', quantity: 156, reorderLevel: 40, nappiCode: '710200045'),
    InventoryItem(name: 'Amlodipine 5mg', category: 'Hypertension', quantity: 8, reorderLevel: 25, nappiCode: '711100056'),
    InventoryItem(name: 'Losartan 50mg', category: 'Hypertension', quantity: 67, reorderLevel: 30, nappiCode: '712000067'),
    InventoryItem(name: 'Fluoxetine 20mg', category: 'Antidepressant', quantity: 0, reorderLevel: 20, nappiCode: '713300078'),
    InventoryItem(name: 'Prednisone 5mg', category: 'Corticosteroid', quantity: 34, reorderLevel: 25, nappiCode: '714400089'),
  ];
}

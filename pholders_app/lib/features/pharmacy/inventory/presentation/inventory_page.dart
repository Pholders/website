import 'package:flutter/material.dart';

/// Pharmacy Inventory page matching the Figma design.
///
/// Shows a filterable table of inventory/stock with status tabs
/// (All, New, Processing, Ready, Out for Delivery, Completed, Cancelled)
/// and a "New Order" button.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _selectedTab = 0;

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFD1F5F5);
  static const Color _pendingOrange = Color(0xFFFBBF24);
  static const Color _processingBlue = Color(0xFF3B82F6);

  final List<String> _tabs = [
    'All',
    'In Stock',
    'Low Stock',
    'Out of Stock',
  ];

  // Mock data
  final List<_InventoryItem> _items = [
    const _InventoryItem(
      medicationId: 'MED-001',
      medicationName: 'Paracetamol 500mg',
      sku: 'SKU-PAR-500',
      quantity: 450,
      reorderLevel: 100,
      unitPrice: 'R2.50',
      status: 'In Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-002',
      medicationName: 'Amoxicillin 250mg',
      sku: 'SKU-AMX-250',
      quantity: 85,
      reorderLevel: 100,
      unitPrice: 'R4.20',
      status: 'Low Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-003',
      medicationName: 'Ibuprofen 200mg',
      sku: 'SKU-IBU-200',
      quantity: 0,
      reorderLevel: 80,
      unitPrice: 'R1.80',
      status: 'Out of Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-004',
      medicationName: 'Aspirin 100mg',
      sku: 'SKU-ASP-100',
      quantity: 320,
      reorderLevel: 100,
      unitPrice: 'R3.15',
      status: 'In Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-005',
      medicationName: 'Lisinopril 10mg',
      sku: 'SKU-LIS-10',
      quantity: 45,
      reorderLevel: 100,
      unitPrice: 'R5.90',
      status: 'Low Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-006',
      medicationName: 'Atorvastatin 20mg',
      sku: 'SKU-ATO-20',
      quantity: 215,
      reorderLevel: 100,
      unitPrice: 'R6.40',
      status: 'In Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-007',
      medicationName: 'Metformin 500mg',
      sku: 'SKU-MET-500',
      quantity: 0,
      reorderLevel: 150,
      unitPrice: 'R2.75',
      status: 'Out of Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-008',
      medicationName: 'Omeprazole 20mg',
      sku: 'SKU-OMP-20',
      quantity: 60,
      reorderLevel: 100,
      unitPrice: 'R4.60',
      status: 'Low Stock',
    ),
    const _InventoryItem(
      medicationId: 'MED-009',
      medicationName: 'Cetirizine 10mg',
      sku: 'SKU-CET-10',
      quantity: 580,
      reorderLevel: 200,
      unitPrice: 'R3.20',
      status: 'In Stock',
    ),
  ];

  List<_InventoryItem> get _filteredItems {
    final tab = _tabs[_selectedTab];
    if (tab == 'All') return _items;
    return _items.where((item) => item.status == tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage medication stock and availability',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        _buildNewOrderButton(),
      ],
    );
  }

  Widget _buildNewOrderButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF309CA3),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/plus-icon.png', width: 18, height: 18, color: Colors.black),
          const SizedBox(width: 8),
          const Text(
            'Add Medication',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        ...List.generate(_tabs.length, (index) {
          final isActive = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : _textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Text(
          'Total Items: ${_items.length}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted),
        ),
      ],
    );
  }

  // ─── Table ───────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final data = _filteredItems;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 1, child: _ColHeader('Med ID')),
                        Expanded(flex: 2, child: _ColHeader('Medication Name')),
                        Expanded(flex: 1, child: _ColHeader('SKU')),
                        Expanded(flex: 1, child: _ColHeader('Quantity')),
                        Expanded(flex: 1, child: _ColHeader('Reorder Level')),
                        Expanded(flex: 1, child: _ColHeader('Unit Price')),
                        Expanded(flex: 1, child: _ColHeader('Status')),
                        Expanded(flex: 1, child: _ColHeader('Action')),
                      ],
                    ),
                  ),
                  // Table rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) => _buildRow(data[index]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return const Color(0xFF34A853); // Green
      case 'Low Stock':
        return _pendingOrange;
      case 'Out of Stock':
        return const Color(0xFFD93025); // Red
      default:
        return _textMuted;
    }
  }

  Widget _buildRow(_InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Medication ID
          Expanded(
            flex: 1,
            child: Text(
              item.medicationId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          // Medication Name
          Expanded(
            flex: 2,
            child: Text(
              item.medicationName,
              style: const TextStyle(fontSize: 13, color: _textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // SKU
          Expanded(
            flex: 1,
            child: Text(
              item.sku,
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          // Quantity
          Expanded(
            flex: 1,
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          // Reorder Level
          Expanded(
            flex: 1,
            child: Text(
              item.reorderLevel.toString(),
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),
          ),
          // Unit Price
          Expanded(
            flex: 1,
            child: Text(
              item.unitPrice,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(item.status),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.status,
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DD0D8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _InventoryItem {
  final String medicationId;
  final String medicationName;
  final String sku;
  final int quantity;
  final int reorderLevel;
  final String unitPrice;
  final String status;

  const _InventoryItem({
    required this.medicationId,
    required this.medicationName,
    required this.sku,
    required this.quantity,
    required this.reorderLevel,
    required this.unitPrice,
    required this.status,
  });
}

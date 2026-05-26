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
    'New',
    'Processing',
    'Ready',
    'Out for Delivery',
    'Completed',
    'Cancelled',
  ];

  // Mock data
  final List<_InventoryItem> _items = List.generate(
    13,
    (i) => const _InventoryItem(
      orderId: '#10234',
      patient: 'Prince Mashumu',
      items: '2 Items',
      total: 'R450',
      payment: 'Pending',
      status: 'Processing',
    ),
  );

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
            'New Order',
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
          'Total: 140',
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
                        Expanded(flex: 2, child: _ColHeader('Order ID')),
                        Expanded(flex: 3, child: _ColHeader('Patient')),
                        Expanded(flex: 2, child: _ColHeader('Items')),
                        Expanded(flex: 2, child: _ColHeader('Total')),
                        Expanded(flex: 2, child: _ColHeader('Payment')),
                        Expanded(flex: 2, child: _ColHeader('Status')),
                        Expanded(flex: 2, child: _ColHeader('Action')),
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

  Widget _buildRow(_InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Order ID
          Expanded(
            flex: 2,
            child: Text(
              item.orderId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          // Patient
          Expanded(
            flex: 3,
            child: Text(
              item.patient,
              style: const TextStyle(fontSize: 13, color: _textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Items
          Expanded(
            flex: 2,
            child: Text(
              item.items,
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          // Total
          Expanded(
            flex: 2,
            child: Text(
              item.total,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          // Payment
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pendingOrange,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.payment,
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _processingBlue,
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
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DD0D8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'Mark Ready',
                  style: TextStyle(
                    fontSize: 12,
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
  final String orderId;
  final String patient;
  final String items;
  final String total;
  final String payment;
  final String status;

  const _InventoryItem({
    required this.orderId,
    required this.patient,
    required this.items,
    required this.total,
    required this.payment,
    required this.status,
  });
}

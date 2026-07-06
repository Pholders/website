import 'package:flutter/material.dart';

import '../data/inventory_catalog.dart';
import '../domain/inventory_item.dart';

/// Pharmacy Inventory / Stock Management page.
///
/// SRS BR-028: Stock visibility, edit levels, low stock indicator.
/// Shows medication items with current stock, reorder level, and status.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _selectedTab = 0;

  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _lowStockRed = Color(0xFFEF4444);
  static const Color _inStockGreen = Color(0xFF34D399);
  static const Color _warningOrange = Color(0xFFFBBF24);

  final List<String> _tabs = ['All', 'In Stock', 'Low Stock', 'Out of Stock'];

  List<InventoryItem> get _stock => InventoryCatalog.items;

  List<InventoryItem> get _filtered {
    switch (_selectedTab) {
      case 1:
        return _stock.where((item) => item.quantity > item.reorderLevel).toList();
      case 2:
        return _stock.where((item) => item.quantity > 0 && item.quantity <= item.reorderLevel).toList();
      case 3:
        return _stock.where((item) => item.quantity == 0).toList();
      default:
        return _stock;
    }
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
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventory', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textDark)),
              SizedBox(height: 4),
              Text('Manage medication stock and availability', style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
        InkWell(
          onTap: _addItem,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/plus-icon.png', width: 18, height: 18, color: Colors.black),
                const SizedBox(width: 8),
                const Text('Add Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        ...List.generate(_tabs.length, (i) {
          final isActive = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_tabs[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : _textMuted)),
              ),
            ),
          );
        }),
        const Spacer(),
        Text('Total: ${_stock.length} items', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted)),
      ],
    );
  }

  Widget _buildTable() {
    final data = _filtered;
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('NAPPI Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 1, child: Text('Reorder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (_, i) => _buildRow(data[i]),
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

  Widget _buildRow(InventoryItem item) {
    final status = item.stockStatus;
    final statusColor = status == 'In Stock' ? _inStockGreen : status == 'Low Stock' ? _warningOrange : _lowStockRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark))),
          Expanded(flex: 2, child: Text(item.category, style: const TextStyle(fontSize: 13, color: _textMuted))),
          Expanded(flex: 2, child: Text(item.nappiCode, style: const TextStyle(fontSize: 13, color: _textMuted))),
          Expanded(flex: 1, child: Text('${item.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: item.quantity <= item.reorderLevel ? _lowStockRed : _textDark))),
          Expanded(flex: 1, child: Text('${item.reorderLevel}', style: const TextStyle(fontSize: 13, color: _textMuted))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                const SizedBox(width: 6),
                Text(status, style: TextStyle(fontSize: 12, color: statusColor)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _editStock(item),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFF6DD0D8), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.black.withValues(alpha: 0.1))),
                child: const Text('Edit Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final nameC = TextEditingController();
    final categoryC = TextEditingController();
    final nappiC = TextEditingController();
    final qtyC = TextEditingController();
    final reorderC = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: nameC, label: 'Medication Name'),
              const SizedBox(height: 10),
              _DialogField(controller: categoryC, label: 'Category'),
              const SizedBox(height: 10),
              _DialogField(controller: nappiC, label: 'NAPPI Code'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _DialogField(controller: qtyC, label: 'Quantity', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _DialogField(controller: reorderC, label: 'Reorder Level', isNumber: true)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isEmpty || categoryC.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                _stock.add(InventoryItem(
                  name: nameC.text,
                  category: categoryC.text,
                  nappiCode: nappiC.text.isNotEmpty ? nappiC.text : '000000000',
                  quantity: int.tryParse(qtyC.text) ?? 0,
                  reorderLevel: int.tryParse(reorderC.text) ?? 30,
                ));
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${nameC.text} added to inventory'),
                backgroundColor: _teal,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _editStock(InventoryItem item) {
    final controller = TextEditingController(text: '${item.quantity}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Stock: ${item.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${item.quantity}  |  Reorder level: ${item.reorderLevel}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New quantity',
                filled: true,
                fillColor: const Color(0xFFE8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null && newQty >= 0) {
                Navigator.pop(ctx);
                setState(() => item.quantity = newQty);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${item.name} stock updated to $newQty'),
                  backgroundColor: _teal,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;

  const _DialogField({required this.controller, required this.label, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFE8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';

/// Pharmacy Order Detail page matching the Figma design.
///
/// Shows full order information including patient info, items table,
/// totals, linked prescription, and payment information.
class OrderDetailPage extends StatelessWidget {

  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);
  static const Color _tableBg = Color(0xFFE8F8F8);
  static const Color _bgLight = Color(0x33309CA3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 12),
            _buildDetailCard(context),
          ],
        ),
      ),
    );
  }

  // ─── Page Header ─────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage customer orders and deliveries',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        Container(
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
        ),
      ],
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final tabs = [
      'All', 'New', 'processing', 'Ready',
      'Out for Delivery', 'Completed', 'Cancelled',
    ];
    return Row(
      children: [
        ...List.generate(tabs.length, (index) {
          final isActive = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : _textMuted,
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        const Text(
          'Total: 140',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted),
        ),
      ],
    );
  }

  // ─── Detail Card ─────────────────────────────────────────────────────────
  Widget _buildDetailCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: _tealBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailHeader(context),
                      const SizedBox(height: 20),
                      _buildOrderMeta(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Patient Information'),
                      const SizedBox(height: 12),
                      _buildField('Patient', 'Maria Wilson'),
                      _buildField('Phone', '12345678900'),
                      _buildField('Email', 'mariawilson@gmail.com'),
                      const SizedBox(height: 24),
                      _buildItemsSection(),
                      const SizedBox(height: 24),
                      _buildTotalSection(),
                      const SizedBox(height: 24),
                      _buildLinkedPrescription(),
                      const SizedBox(height: 24),
                      _buildPaymentInformation(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Detail Header ───────────────────────────────────────────────────────
  Widget _buildDetailHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.pharmacyOrders),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _bgLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 16, color: _teal),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Orders',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '> #10234',
          style: TextStyle(fontSize: 14, color: _textMuted),
        ),
        const Spacer(),
        const _IconBtn(assetPath: 'assets/share-icon.png'),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/printer-icon.png'),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/call-icon.png'),
      ],
    );
  }

  // ─── Order Meta ──────────────────────────────────────────────────────────
  Widget _buildOrderMeta() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order No.',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 2),
              const Text(
                '#10234',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Placed on: 25 Mar 2026 • 10:30 AM',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 10),
              // Processing badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF003BFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF9D358),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Processing',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Text(
          'In-Store Pickup',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ],
    );
  }

  // ─── Section Title ───────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );
  }

  // ─── Field Row ───────────────────────────────────────────────────────────
  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, color: _textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Items Section ───────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Items'),
            const SizedBox(width: 4),
            const Text('(2)', style: TextStyle(fontSize: 14, color: _textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Header
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Text('Order ID',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Dosage',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('Qty',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Price',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD1F5F5)),
              _buildItemRow('1.', 'Isotretinoin', '20mg', '1', 'R300'),
              _buildItemRow('2.', 'Isotretinoin', '20mg', '1', 'R300'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(
      String num, String name, String dosage, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(num,
                style: const TextStyle(fontSize: 12, color: _textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(name,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(dosage,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
          ),
          Expanded(
            flex: 1,
            child: Text(qty,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(price,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
        ],
      ),
    );
  }

  // ─── Total Section ───────────────────────────────────────────────────────
  Widget _buildTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Total'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildTotalRow('Subtotal', 'R600'),
              _buildTotalRow('Delivery', 'R0'),
              const Divider(height: 16, color: Color(0xFFD1F5F5)),
              _buildTotalRow('Total', 'R600', bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: _textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Linked Prescription ─────────────────────────────────────────────────
  Widget _buildLinkedPrescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Linked Prescription'),
        const SizedBox(height: 12),
        _buildField('Issued by', 'Dr Sam Smith'),
        _buildField('Medication', 'Isotreionion'),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'View Prescription',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Payment Information ─────────────────────────────────────────────────
  Widget _buildPaymentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Information'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildTotalRow('Payment Method', 'Card'),
              _buildTotalRow('Status', 'Paid'),
              _buildTotalRow('Transaction ID', 'TXN123456'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.assetPath});
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0x33309CA3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Image.asset(assetPath, width: 16, height: 16),
      ),
    );
  }
}

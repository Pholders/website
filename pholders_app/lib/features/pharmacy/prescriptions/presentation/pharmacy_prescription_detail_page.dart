import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../../../../core/routing/app_routes.dart';
import '../data/prescription_sample_data.dart';
import 'prescription_document_pdf.dart';

/// Pharmacy Prescription Detail page matching the Figma design.
///
/// Shows full prescription information including patient info,
/// prescription details, instructions, doctor info, and digital signature.
class PharmacyPrescriptionDetailPage extends StatefulWidget {

  const PharmacyPrescriptionDetailPage({
    super.key,
    required this.prescriptionId,
  });
  final String prescriptionId;

  @override
  State<PharmacyPrescriptionDetailPage> createState() =>
      _PharmacyPrescriptionDetailPageState();
}

class _PharmacyPrescriptionDetailPageState
    extends State<PharmacyPrescriptionDetailPage> {
  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _tealLight = Color(0xFFE8F8F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);
  static const Color _bgLight = Color(0x33309CA3);

  String _currentStatus = 'New';

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
                'Prescriptions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage incoming prescriptions and dispensing',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        _buildScanQrButton(),
      ],
    );
  }

  Widget _buildScanQrButton() {
    return Container(
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset('assets/scanner-icon.png', color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _teal,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final tabs = ['All', 'New', 'Accepted', 'In-Progress', 'Ready', 'Dispensed'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isActive = index == 0;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                    _buildSignedByInfo(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Patient Information'),
                    const SizedBox(height: 12),
                    _buildField('Patient', 'Maria Wilson'),
                    _buildField('ID', '12345678900'),
                    _buildField('Date of Birth', '01 Mar 1998'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Medical Aid Details'),
                    const SizedBox(height: 12),
                    _buildField('Medical Aid', 'Discovery Health'),
                    _buildField('Plan', 'KeyCare Plus'),
                    _buildField('Member No.', 'DH-90012345'),
                    _buildField('Dependent', 'Principal Member'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Collection & Delivery'),
                    const SizedBox(height: 12),
                    _buildField('Preference', 'In-Store Collection'),
                    _buildField('Pharmacy', 'Pholders Pharmacy — Sandton'),
                    _buildField('Generic Sub.', 'Allowed on all products'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Payment Status'),
                    const SizedBox(height: 12),
                    _buildField('Method', 'Medical Aid'),
                    _buildField('Status', 'Covered — R0 co-pay'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Prescription Details'),
                    const SizedBox(height: 12),
                    _buildField('Medication', 'Panado'),
                    _buildField('Dosage', '20mg'),
                    _buildField('Frequency', 'Once daily'),
                    _buildField('Duration', '30 Days'),
                    _buildField('Quantity', '30 Tablets'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Instructions'),
                    const SizedBox(height: 12),
                    _buildField('Instructions', '1. Take after meals'),
                    _buildFieldOnly('2. Avoid alcohol'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Doctor Information'),
                    const SizedBox(height: 12),
                    _buildField('Doctor', 'Dr Sam Smith'),
                    _buildField('HPCSA', 'MP12345678'),
                    _buildField('Practice', 'Mashumu Medical Practice'),
                    const SizedBox(height: 28),
                    _buildDigitalSignature(),
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
          onTap: () => context.go(AppRoutes.pharmacyPrescriptions),
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
          'Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '> Maria Wilson',
          style: const TextStyle(fontSize: 14, color: _textMuted),
        ),
        const Spacer(),
        // Action button — changes based on current status
        InkWell(
          onTap: _currentStatus != 'Dispensed' ? _handleAction : null,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _currentStatus != 'Dispensed' ? _tealBorder : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Text(
              _actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _currentStatus != 'Dispensed' ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Action icons
        _IconBtn(assetPath: 'assets/printer-icon.png', onTap: _printPrescriptionPdf),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/share-icon.png'),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/call-icon.png'),
      ],
    );
  }

  // ─── Signed By Info ──────────────────────────────────────────────────────
  Widget _buildSignedByInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digitally signed by',
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 2),
              const Text(
                'Dr Sam Smith',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'HPCSA:',
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
              const Text(
                'MP1234567',
                style: TextStyle(fontSize: 13, color: _textDark),
              ),
              const SizedBox(height: 8),
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
                        color: Color(0xFF001A8C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Verified',
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
        // Signature stamp image placeholder
        const Text(
          '01 Mar 2026',
          style: const TextStyle(fontSize: 13, color: _textMuted),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
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

  /// Field without a label (continuation of previous field).
  Widget _buildFieldOnly(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const SizedBox(width: 136),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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

  // ─── Digital Signature ───────────────────────────────────────────────────
  Widget _buildDigitalSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Digital Signature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Digital Preview',
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
        const SizedBox(height: 12),
        // Signature box
        Container(
          width: 120,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _teal.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(80, 50),
              painter: _SignaturePainter(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Digitally signed on 25 Mar 2026',
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
        const SizedBox(height: 2),
        const Text(
          'Verification Status',
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
      ],
    );
  }

  // ─── Claim / Status Progression ────────────────────────────────────────────

  String get _actionLabel {
    switch (_currentStatus) {
      case 'New':
        return 'Accept';
      case 'Accepted':
        return 'Process';
      case 'In-Progress':
        return 'Dispense';
      case 'Ready':
        return 'Complete';
      case 'Dispensed':
        return 'Done';
      default:
        return 'Accept';
    }
  }

  String? get _nextStatus {
    switch (_currentStatus) {
      case 'New':
        return 'Accepted';
      case 'Accepted':
        return 'In-Progress';
      case 'In-Progress':
        return 'Ready';
      case 'Ready':
        return 'Dispensed';
      default:
        return null;
    }
  }

  void _handleAction() {
    final next = _nextStatus;
    if (next == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _currentStatus == 'New' ? 'Claim Prescription?' : 'Update Status?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          _currentStatus == 'New'
              ? 'Claiming this prescription will lock it to your pharmacy. No other pharmacy can claim it.'
              : 'Move prescription status to "$next"? The patient will be notified.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentStatus = next);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Patient notified — Script status: $next'),
                  backgroundColor: const Color(0xFF309CA3),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF309CA3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _printPrescriptionPdf() async {
    final document = samplePrescriptionDocument(
      prescriptionId: widget.prescriptionId,
      currentStatus: _currentStatus,
    );
    final Uint8List pdfBytes = await PrescriptionDocumentPdf.build(document);
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..target = '_blank'
      ..click();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription PDF opened'),
        backgroundColor: Color(0xFF309CA3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    unawaited(
      Future<void>.delayed(const Duration(seconds: 10)).then((_) {
        html.Url.revokeObjectUrl(url);
      }),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.assetPath, this.onTap});
  final String assetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
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
      ),
    );
  }
}

/// Simple custom painter to draw a mock signature squiggle.
class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF309CA3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.25, size.height * 0.2,
        size.width * 0.35, size.height * 0.9,
        size.width * 0.5, size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.65, size.height * 0.1,
        size.width * 0.75, size.height * 0.8,
        size.width * 0.9, size.height * 0.4,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

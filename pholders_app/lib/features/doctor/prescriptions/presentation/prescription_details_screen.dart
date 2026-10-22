import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/prescriptions_repository.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';

// ─── Prescription Details Screen ──────────────────────────────────────────────
class PrescriptionDetailsScreen extends StatefulWidget {

  const PrescriptionDetailsScreen({
    super.key,
    required this.prescription,
    required this.onBack,
  });
  final Prescription prescription;
  final VoidCallback onBack;

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  /// True while a PDF is being fetched, so the two buttons can be held shut
  /// rather than firing a second request on an impatient double-click.
  bool _busy = false;

  Prescription get prescription => widget.prescription;

  /// The sample rows carry ids like `RX001`, so there is nothing on the
  /// server to fetch. Null disables the buttons instead of failing on tap.
  int? get _serverId => int.tryParse(prescription.id);

  Future<void> _withPdf(
    Future<void> Function(Uint8List bytes) use, {
    required bool forPrinting,
  }) async {
    final id = _serverId;
    if (id == null || _busy) return;

    setState(() => _busy = true);
    try {
      final bytes = await sl<PrescriptionsRepository>()
          .fetchPdf(id, forPrinting: forPrinting);
      if (!mounted) return;
      await use(bytes);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _withPdf(
        forPrinting: false,
        (bytes) => Printing.sharePdf(
          bytes: bytes,
          filename: 'prescription-${prescription.dosage}.pdf',
        ),
      );

  Future<void> _print() => _withPdf(
        forPrinting: true,
        (bytes) => Printing.layoutPdf(onLayout: (_) async => bytes),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RxColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────────────
            Row(
              children: [
                // Back arrow + title
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: RxColors.tealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: RxColors.teal),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: RxColors.textPrimary,
                  ),
                ),
                const Spacer(),

                // Approved badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBg(prescription.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(prescription.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(prescription.status),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Share and print both fetch the real document from the
                // server — the same PDF the patient gets, not a copy drawn
                // here, so the two can never disagree.
                //
                // There is no edit button. A signed prescription may not be
                // altered; revoking it is the only way back, and that lives
                // on the row's menu in the list.
                _IconBtn(
                  icon: Icons.share_outlined,
                  tooltip: 'Download a copy',
                  onTap: _serverId == null || _busy ? null : _share,
                ),
                const SizedBox(width: 8),

                _IconBtn(
                  icon: Icons.print_outlined,
                  tooltip: 'Print',
                  onTap: _serverId == null || _busy ? null : _print,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Detail fields ────────────────────────────────────────────────
            _PxDetailField(
              label: 'Patient',
              value: prescription.patientName,
            ),
            const SizedBox(height: 14),
            _PxDetailField(
              label: 'Medication',
              value: prescription.medication,
            ),
            const SizedBox(height: 14),
            _PxDetailField(
              label: 'Dosage',
              value: '${prescription.dosage} once daily',
            ),
            const SizedBox(height: 14),
            const _PxDetailField(
              label: 'Duration',
              value: '30 days',
            ),
            const SizedBox(height: 14),
            _PxDetailField(
              label: 'Date Issued',
              value: '${prescription.dateIssued} 2026',
            ),
            const SizedBox(height: 14),
            _PxDetailField(
              label: 'Status',
              value: _statusLabel(prescription.status),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _statusLabel(RxStatus s) {
    switch (s) {
      case RxStatus.approved: return 'Approved';
      case RxStatus.pending: return 'Pending';
      case RxStatus.dispensed: return 'Dispensed';
      case RxStatus.expired: return 'Expired';
      case RxStatus.revoked: return 'Revoked';
    }
  }

  Color _statusBg(RxStatus s) {
    switch (s) {
      case RxStatus.approved: return RxColors.approvedBg;
      case RxStatus.pending: return RxColors.pendingBg;
      case RxStatus.dispensed: return RxColors.dispensedBg;
      case RxStatus.expired: return RxColors.expiredBg;
      case RxStatus.revoked: return RxColors.expiredBg;
    }
  }

  Color _statusColor(RxStatus s) {
    switch (s) {
      case RxStatus.approved: return RxColors.approvedText;
      case RxStatus.pending: return RxColors.pendingText;
      case RxStatus.dispensed: return RxColors.dispensedText;
      case RxStatus.expired: return RxColors.expiredText;
      case RxStatus.revoked: return RxColors.expiredText;
    }
  }
}

// ─── Detail field ─────────────────────────────────────────────────────────────
class _PxDetailField extends StatelessWidget {

  const _PxDetailField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: RxColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: RxColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RxColors.border),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: RxColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Icon button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;

  /// Null disables the button: it greys out and stops responding, rather
  /// than looking live and doing nothing when tapped.
  final Future<void> Function()? onTap;
  final String? tooltip;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = enabled),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? () => widget.onTap!() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _hovered ? RxColors.tealLight : RxColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RxColors.border),
          ),
          child: Icon(widget.icon,
              size: 16,
              color: !enabled
                  ? RxColors.textSecondary.withValues(alpha: 0.4)
                  : _hovered
                      ? RxColors.teal
                      : RxColors.textSecondary),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(
      message: enabled
          ? widget.tooltip!
          : '${widget.tooltip!} — not available for sample data',
      child: button,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';

// ─── Prescription Details Screen ──────────────────────────────────────────────
class PrescriptionDetailsScreen extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onBack;

  const PrescriptionDetailsScreen({
    super.key,
    required this.prescription,
    required this.onBack,
  });

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
                  onTap: onBack,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
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

                // Share icon
                _IconBtn(
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 8),

                // Print icon
                _IconBtn(
                  icon: Icons.print_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 8),

                // Edit icon
                _IconBtn(
                  icon: Icons.edit_outlined,
                  onTap: () {},
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
            _PxDetailField(
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
  final String label;
  final String value;

  const _PxDetailField({required this.label, required this.value});

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
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
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
              color: _hovered ? RxColors.teal : RxColors.textSecondary),
        ),
      ),
    );
  }
}

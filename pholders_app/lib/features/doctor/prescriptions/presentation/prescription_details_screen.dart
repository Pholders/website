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
    final rx = prescription;
    final issued = rx.issuedOn;
    final facts = <Widget>[
      _PxDetailField(label: 'Patient', value: rx.patientName),
      // The list the app reads carries no medicines; the diagnosis and the
      // reference are what it does carry. The medicines are in the PDF.
      _PxDetailField(label: 'Diagnosis', value: rx.medication),
      _PxDetailField(label: 'Reference', value: rx.dosage),
      _PxDetailField(
        label: 'Date issued',
        value: issued == null ? rx.dateIssued : _longDate(issued),
      ),
      _PxDetailField(
        label: 'Status',
        child: Align(
          alignment: Alignment.centerLeft,
          child: _StatusPill(status: rx.status),
        ),
      ),
      if (rx.note != null)
        _PxDetailField(
          label: rx.status == RxStatus.revoked ? 'Revoked' : 'Dispensing',
          value: rx.note!,
        ),
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'The medicines on this prescription are in its document: '
          'download or print it with the buttons above.',
          style: TextStyle(fontSize: 13, color: RxColors.textSecondary),
        ),
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      // Given a height, the card fills it and its fields scroll inside;
      // otherwise the card grows with them.
      final fill = c.hasBoundedHeight && c.maxHeight >= 360;
      final card = Container(
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6DD0D8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // ── Card header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: RxColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication,
                        size: 20, color: RxColors.textPrimary),
                  ),
                  const SizedBox(width: 14),
                  const Text('Details',
                      style:
                          TextStyle(fontSize: 20, color: RxColors.textPrimary)),
                  const Spacer(),
                  // Share and print both fetch the real document from the
                  // server: the same PDF the patient gets, so the two can
                  // never disagree. There is no edit: a written prescription
                  // cannot be altered; revoking it is the way back.
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
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back,
                        size: 18, color: Color(0xFF2E9FA5)),
                    label: const Text('Back to prescriptions',
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2E9FA5))),
                  ),
                ],
              ),
              const Divider(height: 22, thickness: 1.5, color: RxColors.border),
              if (fill)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    children: facts,
                  ),
                )
              else
                ...facts,
            ],
          ),
        ),
      );

      return Material(
        color: Colors.transparent,
        child: fill
            ? Padding(padding: const EdgeInsets.all(4), child: card)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(4), child: card),
      );
    });
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "22 Oct 2026".
  static String _longDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day} ${_months[l.month - 1]} ${l.year}';
  }
}

/// The status as the table shows it: a solid pill, white text.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final RxStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, label) = switch (status) {
      RxStatus.approved => (const Color(0xFF6DD0D8), 'Approved'),
      RxStatus.pending => (const Color(0xFFF2B648), 'Pending'),
      RxStatus.dispensed => (const Color(0xFF5DBB7B), 'Dispensed'),
      RxStatus.revoked => (const Color(0xFFEE8A8A), 'Revoked'),
      RxStatus.expired => (const Color(0xFFEE8A8A), 'Expired'),
    };
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

// ─── Detail field ─────────────────────────────────────────────────────────────
/// A label over its pale teal box, as on a medication's details.
class _PxDetailField extends StatelessWidget {
  const _PxDetailField({required this.label, this.value, this.child})
      : assert(value != null || child != null);
  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF8A8A8A))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF3F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFC9E9EC)),
            ),
            child: child ??
                SelectableText(value!,
                    style: const TextStyle(
                        fontSize: 18, color: Color(0xFF6C7A7B))),
          ),
        ],
      ),
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
      message: enabled ? widget.tooltip! : '${widget.tooltip!}: please wait',
      child: button,
    );
  }
}

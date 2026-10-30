import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart' show Patient;
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart' as api;
import 'package:pholders_app/features/doctor/prescriptions/data/models/signing_receipt.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/interaction_check_dialog.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/signing_receipt_dialog.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/new_prescription_dialog.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescription_details_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class RxColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const cardBg = Color(0xFFFFFFFF);
  static const approvedBg = Color(0xFFD9F3F3);
  static const approvedText = Color(0xFF2EC4C4);
  static const pendingBg = Color(0xFFFFF3DC);
  static const pendingText = Color(0xFFF5A623);
  static const dispensedBg = Color(0xFFE8F5E9);
  static const dispensedText = Color(0xFF4CAF50);
  static const expiredBg = Color(0xFFFFEEEE);
  static const expiredText = Color(0xFFFF6B6B);
  static const amber = Color(0xFFF5A623);
}

// ─── Data model ───────────────────────────────────────────────────────────────
enum RxStatus { approved, pending, dispensed, expired, revoked }

class Prescription {

  const Prescription({
    required this.id,
    required this.patientName,
    required this.medication,
    required this.dosage,
    required this.dateIssued,
    required this.status,
    this.note,
  });
  final String id;
  final String patientName;
  final String medication;
  final String dosage;
  final String dateIssued;
  final RxStatus status;

  /// Read-only detail behind the status: which pharmacy dispensed it and
  /// when, or why it was revoked. The doctor never sets either.
  final String? note;
}

/// Whether [p] matches what the doctor typed: every word must appear in the
/// patient's name, the diagnosis or the prescription reference.
bool prescriptionMatches(Prescription p, String query) {
  final haystack = '${p.patientName} ${p.medication} ${p.dosage}'.toLowerCase();
  return query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .every(haystack.contains);
}

// ─── Prescriptions Screen ─────────────────────────────────────────────────────
class PrescriptionsScreen extends StatefulWidget {

  const PrescriptionsScreen({super.key, this.patient});
  final Patient? patient;

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  int _filterIndex = 0;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Prescription? _selectedPrescription; // null = list, non-null = details

  /// Opened from a patient's profile, only that patient's prescriptions are
  /// shown, filtered from the doctor's own list (the backend has no
  /// per-patient list for doctors). It used to show eight invented
  /// Isotretinoin scripts under the real patient's name.
  int? get _patientId =>
      widget.patient == null ? null : int.tryParse(widget.patient!.id);

  /// Rows from the API, refreshed by the store.
  List<Prescription> _livePrescriptions = const [];

  List<Prescription> get _source => _livePrescriptions;

  /// Opens the real create form. The list refreshes itself on success, so
  /// nothing needs adding to local state here.
  Future<void> _newPrescription() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const NewPrescriptionDialog(),
    );
  }

  /// Runs the drug interaction check and shows the report.
  ///
  /// Most useful before signing: a signed prescription cannot be edited, so
  /// anything flagged afterwards can only be revoked.
  void _checkInteractions(Prescription rx) {
    showDialog<void>(
      context: context,
      builder: (_) => InteractionCheckDialog(
        prescriptionId: int.parse(rx.id),
        patientName: rx.patientName,
      ),
    );
  }

  /// The prescription whose receipt has already been shown, so a rebuild
  /// cannot reopen the dialog over itself.
  int? _receiptShownFor;

  /// Shows the QR and access link as soon as signing returns them.
  ///
  /// It has to be automatic: the token exists only in the sign response, so
  /// there is no screen the doctor could navigate back to for it.
  void _maybeShowReceipt(SigningReceipt? receipt) {
    if (receipt == null || _receiptShownFor == receipt.prescriptionId) return;
    _receiptShownFor = receipt.prescriptionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SigningReceiptDialog(receipt: receipt),
      );
    });
  }

  /// Signs a prescription after confirming, since signing is what makes it
  /// legally valid and dispensable.
  Future<void> _signPrescription(Prescription rx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign this prescription?'),
        content: Text(
          'Signing ${rx.dosage} for ${rx.patientName} makes it valid and '
          'dispensable by a pharmacy. It cannot be edited afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    StoreProvider.of<AppState>(context)
        .dispatch(SignPrescriptionAction(prescriptionId: int.parse(rx.id)));
  }

  /// Revokes a signed prescription so it can no longer be dispensed.
  ///
  /// A reason is required, not optional politeness: the backend rejects a
  /// revoke without one, and it is what the record keeps in place of a delete.
  Future<void> _revokePrescription(Prescription rx) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final text = controller.text.trim();
          return AlertDialog(
            title: const Text('Revoke this prescription?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rx.dosage} for ${rx.patientName} will no longer be '
                  'dispensable. This cannot be undone.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'e.g. Prescribed in error',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: RxColors.expiredText),
                onPressed:
                    text.isEmpty ? null : () => Navigator.pop(ctx, text),
                child: const Text('Revoke'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    StoreProvider.of<AppState>(context).dispatch(
      RevokePrescriptionAction(
        prescriptionId: int.parse(rx.id),
        reason: reason,
      ),
    );
  }

  /// Maps an API prescription onto the row model this screen renders.
  ///
  /// `GET /prescriptions/doctor/all` carries no medicines, so the medication
  /// and dosage columns hold the diagnosis and the reference number instead —
  /// the headers change to match when live.
  static Prescription _fromApi(api.Prescription p) {
    return Prescription(
      id: p.id.toString(),
      patientName: p.patientName,
      medication: p.diagnosis ?? '-',
      dosage: p.number,
      dateIssued: p.formattedDate,
      // Dispensing is tracked separately from the signature, so a dispensed
      // script still reads as 'signed'. A revoke outranks it: a withdrawn
      // script should not look fulfilled.
      status: switch (p.status) {
        api.PrescriptionStatus.revoked => RxStatus.revoked,
        api.PrescriptionStatus.signed =>
          p.isDispensed ? RxStatus.dispensed : RxStatus.approved,
        api.PrescriptionStatus.pending => RxStatus.pending,
        api.PrescriptionStatus.unknown => RxStatus.pending,
      },
      note: p.dispensedSummary ??
          (p.revokeReason == null ? null : 'Revoked: ${p.revokeReason}'),
    );
  }

  static const _filters = ['All', 'Pending', 'Approved', 'Dispensed', 'Expired'];

    @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context)
            .dispatch(const LoadPrescriptionsAction());
      }
    });
  }

  List<Prescription> get _filtered {
    final map = {
      1: RxStatus.pending,
      2: RxStatus.approved,
      3: RxStatus.dispensed,
      4: RxStatus.expired,
    };
    return _source
        .where((p) => _filterIndex == 0 || p.status == map[_filterIndex])
        .where((p) => prescriptionMatches(p, _query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sample-data mode renders straight from local state.
    // Live mode feeds the rows from the store, keeping the same layout.
    return StoreConnector<AppState, _RxViewModel>(
      converter: _RxViewModel.fromStore,
      builder: (context, vm) {
        final patientId = _patientId;
        _livePrescriptions = vm.prescriptions
            .where((p) => patientId == null || p.patientId == patientId)
            .map(_fromApi)
            .toList();
        // Checked on every build rather than via onDidChange: the receipt
        // must not be missed, and the guard inside makes repeats harmless.
        _maybeShowReceipt(vm.signingReceipt);

        if (vm.isLoading && !vm.hasLoadedOnce) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: RxColors.teal),
                  SizedBox(height: 16),
                  // The API sleeps when idle, so a first load can take ~30s.
                  Text('Loading prescriptions...',
                      style: TextStyle(color: RxColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (vm.errorMessage != null && vm.prescriptions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 40, color: RxColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: RxColors.textSecondary)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => StoreProvider.of<AppState>(context)
                        .dispatch(const LoadPrescriptionsAction()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    // Show details screen when a prescription is selected
    if (_selectedPrescription != null) {
      return PrescriptionDetailsScreen(
        prescription: _selectedPrescription!,
        onBack: () => setState(() => _selectedPrescription = null),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
        decoration: BoxDecoration(
          color: RxColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RxColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RxColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_outlined,
                      color: RxColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Prescriptions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RxColors.textPrimary),
                ),
                const Spacer(),
                // New Prescription button
                ElevatedButton.icon(
                  onPressed: _newPrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RxColors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 18),
                  label: const Text('New Prescription',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Create, review, and manage patient prescriptions',
              style: TextStyle(
                  fontSize: 13, color: RxColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // ── Filter tabs and search ──────────────────────────────────────
            Row(
              children: [
                // On a narrow window the chips scroll sideways rather than
                // pushing the search box off the edge.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filters.length, (i) {
                final active = i == _filterIndex;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? RxColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: active ? RxColors.teal : RxColors.border),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : RxColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  height: 40,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) => TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search patient, diagnosis or reference',
                        hintStyle: const TextStyle(
                            fontSize: 12, color: RxColors.textSecondary),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: RxColors.textSecondary),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: RxColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: RxColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Table header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: RxColors.border)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: _RxHeaderCell('Patient')),
                  Expanded(flex: 3, child: _RxHeaderCell('Diagnosis')),
                  Expanded(flex: 2, child: _RxHeaderCell('Reference')),
                  Expanded(flex: 2, child: _RxHeaderCell('Date Issued')),
                  Expanded(flex: 2, child: _RxHeaderCell('Status')),
                  Expanded(flex: 2, child: _RxHeaderCell('Actions')),
                ],
              ),
            ),

            // ── Table rows ──────────────────────────────────────────────────
            _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                          _query.trim().isEmpty
                              ? 'No prescriptions found'
                              : 'No prescriptions match "${_query.trim()}"',
                          style: const TextStyle(
                              color: RxColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: _filtered
                        .map((rx) => _RxRow(
                              prescription: rx,
                              onViewDetails: () => setState(
                                  () => _selectedPrescription = rx),
                              // Signing and revoking hit the API, so they are
                              // only offered against real prescriptions.
                              onSign: rx.status == RxStatus.pending
                                  ? () => _signPrescription(rx)
                                  : null,
                              onRevoke: rx.status == RxStatus.approved
                                  ? () => _revokePrescription(rx)
                                  : null,
                              onCheckInteractions: () => _checkInteractions(rx),
                            ))
                        .toList(),
                  ),
          ],
        ),        // closes Column
        ),        // closes Container
      ),          // closes SingleChildScrollView
    );            // closes Material
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────
class _RxHeaderCell extends StatelessWidget {
  const _RxHeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RxColors.textSecondary));
  }
}

// ─── Prescription row ─────────────────────────────────────────────────────────
class _RxRow extends StatefulWidget {

  const _RxRow({
    required this.prescription,
    required this.onViewDetails,
    this.onSign,
    this.onRevoke,
    this.onCheckInteractions,
  });
  final Prescription prescription;
  final VoidCallback onViewDetails;

  /// Null when the action does not apply to this prescription's status.
  final VoidCallback? onSign;
  final VoidCallback? onRevoke;

  /// Null for sample rows, which have no prescription on the server to check.
  final VoidCallback? onCheckInteractions;

  @override
  State<_RxRow> createState() => _RxRowState();
}

class _RxRowState extends State<_RxRow> {
  bool _hovered = false;

  void _showMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (_) => _RxActionsMenu(
        onViewDetails: widget.onViewDetails,
        onSign: widget.onSign,
        onRevoke: widget.onRevoke,
        onCheckInteractions: widget.onCheckInteractions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rx = widget.prescription;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onViewDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? RxColors.tealLight.withValues(alpha: 0.4)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
            // Patient name + avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: RxColors.tealLight,
                    child: Text(
                      rx.patientName
                          .split(' ')
                          .map((w) => w[0])
                          .join(),
                      style: const TextStyle(
                          color: RxColors.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(rx.patientName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: RxColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            // Medication
            Expanded(
              flex: 3,
              child: Text(rx.medication,
                  style: const TextStyle(
                      fontSize: 13, color: RxColors.textSecondary)),
            ),

            // Dosage
            Expanded(
              flex: 2,
              child: Text(rx.dosage,
                  style: const TextStyle(
                      fontSize: 13, color: RxColors.textSecondary)),
            ),

            // Date issued
            Expanded(
              flex: 2,
              child: Text(rx.dateIssued,
                  style: const TextStyle(
                      fontSize: 13, color: RxColors.textSecondary)),
            ),

                                    // Status badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RxStatusBadge(status: rx.status),
                  if (rx.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        rx.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: RxColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _RxActionBtn(
                    icon: Icons.more_vert,
                    onTap: () => _showMenu(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _RxStatusBadge extends StatelessWidget {
  const _RxStatusBadge({required this.status});
  final RxStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;
    switch (status) {
      case RxStatus.approved:
        bg = RxColors.approvedBg;
        text = RxColors.approvedText;
        label = 'Approved';
      case RxStatus.pending:
        bg = RxColors.pendingBg;
        text = RxColors.pendingText;
        label = 'Pending';
      case RxStatus.dispensed:
        bg = RxColors.dispensedBg;
        text = RxColors.dispensedText;
        label = 'Dispensed';
      case RxStatus.revoked:
        bg = RxColors.expiredBg;
        text = RxColors.expiredText;
        label = 'Revoked';
      case RxStatus.expired:
        bg = RxColors.expiredBg;
        text = RxColors.expiredText;
        label = 'Expired';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text)),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
class _RxActionBtn extends StatelessWidget {
  const _RxActionBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: RxColors.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RxColors.border),
        ),
        child: Icon(icon, size: 14, color: RxColors.textSecondary),
      ),
    );
  }
}

// ─── Actions menu ─────────────────────────────────────────────────────────────
class _RxActionsMenu extends StatelessWidget {

  const _RxActionsMenu({
    required this.onViewDetails,
    this.onSign,
    this.onRevoke,
    this.onCheckInteractions,
  });
  final VoidCallback onViewDetails;
  final VoidCallback? onSign;
  final VoidCallback? onRevoke;
  final VoidCallback? onCheckInteractions;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _RxAction(label: 'View Details', icon: Icons.visibility_outlined,
          onTap: () { Navigator.pop(context); onViewDetails(); }),
      if (onCheckInteractions != null)
        _RxAction(label: 'Check Interactions', icon: Icons.science_outlined,
            onTap: () { Navigator.pop(context); onCheckInteractions!(); }),
      // Only offered while the prescription is still unsigned.
      if (onSign != null)
        _RxAction(label: 'Sign Prescription', icon: Icons.draw_outlined,
            onTap: () { Navigator.pop(context); onSign!(); }),
      // Only offered once it is signed and therefore dispensable.
      if (onRevoke != null)
        _RxAction(label: 'Revoke Prescription', icon: Icons.block_outlined,
            onTap: () { Navigator.pop(context); onRevoke!(); }),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 270,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: RxColors.textPrimary, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: RxColors.textPrimary),
                    ),
                  ),
                ),
              ),
              ...List.generate(actions.length, (i) {
                final isLast = i == actions.length - 1;
                return Column(
                  children: [
                    _RxActionMenuItem(
                      label: actions[i].label,
                      icon: actions[i].icon,
                      onTap: actions[i].onTap,
                      isDanger: actions[i].label == 'Delete',
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1,
                          color: RxColors.border,
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RxAction {
  const _RxAction(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _RxActionMenuItem extends StatefulWidget {

  const _RxActionMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  State<_RxActionMenuItem> createState() => _RxActionMenuItemState();
}

class _RxActionMenuItemState extends State<_RxActionMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDanger
        ? Colors.red.shade400
        : _hovered
            ? RxColors.teal
            : RxColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          color: _hovered
              ? (widget.isDanger
                  ? Colors.red.shade50
                  : RxColors.tealLight)
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon, size: 17, color: color),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: _hovered
                          ? FontWeight.w500
                          : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Store bindings ---------------------------------------------------------

class _RxViewModel {
  const _RxViewModel({
    required this.prescriptions,
    required this.isLoading,
    required this.hasLoadedOnce,
    this.errorMessage,
    this.signingReceipt,
  });

  factory _RxViewModel.fromStore(Store<AppState> store) {
    final state = store.state.prescriptionsState;
    return _RxViewModel(
      prescriptions: state.prescriptions,
      isLoading: state.isLoading,
      hasLoadedOnce: state.hasLoadedOnce,
      errorMessage: state.errorMessage,
      signingReceipt: state.signingReceipt,
    );
  }

  final List<api.Prescription> prescriptions;
  final bool isLoading;
  final bool hasLoadedOnce;
  final String? errorMessage;
  final SigningReceipt? signingReceipt;
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart'
    as api;
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
    this.issuedOn,
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

  /// When it was written, for the details' full date ("22 Oct 2026").
  final DateTime? issuedOn;
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

  /// The table's rows, which scroll under a fixed header.
  final _rowsScroll = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _rowsScroll.dispose();
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
                style: FilledButton.styleFrom(
                    backgroundColor: RxColors.expiredText),
                onPressed: text.isEmpty ? null : () => Navigator.pop(ctx, text),
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
      issuedOn: p.createdAt,
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

  static const _filters = [
    'All',
    'Pending',
    'Approved',
    'Dispensed',
    'Expired'
  ];

  @override
  void initState() {
    super.initState();
    // The list is loaded once, at sign-in, and refreshes itself after a
    // prescription is written, signed or revoked. Opening the tab only
    // asks for it if that first load has not happened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = StoreProvider.of<AppState>(context);
      final state = store.state.prescriptionsState;
      if (!state.hasLoadedOnce && !state.isLoading) {
        store.dispatch(const LoadPrescriptionsAction());
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

    Widget row(Prescription rx) => _RxRow(
          prescription: rx,
          onViewDetails: () => setState(() => _selectedPrescription = rx),
          onSign: rx.status == RxStatus.pending
              ? () => _signPrescription(rx)
              : null,
          onRevoke: rx.status == RxStatus.approved
              ? () => _revokePrescription(rx)
              : null,
          onCheckInteractions: () => _checkInteractions(rx),
        );

    return LayoutBuilder(builder: (context, c) {
      // Given a height, the card fills it and only the rows scroll, under
      // the header, filters and column labels. Too short a space, or none
      // given, and the whole card scrolls instead.
      final fill = c.hasBoundedHeight && c.maxHeight >= 420;
      final rows = _filtered;

      final card = _RxEdgedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────────
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
                      color: RxColors.textPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Prescriptions',
                  style: TextStyle(fontSize: 20, color: RxColors.textPrimary),
                ),
                const Spacer(),
                _NewPrescriptionButton(onTap: _newPrescription),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Create, review, and manage patient prescriptions',
              style: TextStyle(fontSize: 16, color: Color(0xFF9AA5A6)),
            ),
            const SizedBox(height: 22),

            // ── Filter tabs and search ────────────────────────────────────────
            Row(
              children: [
                // On a narrow window the chips scroll sideways rather than
                // pushing the search box off the edge.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _filters.length; i++)
                          _RxFilterChip(
                            label: _filters[i],
                            selected: i == _filterIndex,
                            onTap: () => setState(() => _filterIndex = i),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  height: 36,
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
                            size: 18, color: RxColors.textPrimary),
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
                        fillColor: RxColors.tealLight,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Table header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: RxColors.border, width: 2)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: _patientFlex, child: _RxHeaderCell('Patient')),
                  // The list carries no medicines, so the diagnosis and the
                  // reference stand where the design has medication and dosage.
                  Expanded(
                      flex: _diagnosisFlex, child: _RxHeaderCell('Diagnosis')),
                  Expanded(
                      flex: _referenceFlex, child: _RxHeaderCell('Reference')),
                  Expanded(
                      flex: _dateFlex, child: _RxHeaderCell('Date Issued')),
                  Expanded(flex: _statusFlex, child: _RxHeaderCell('Status')),
                  SizedBox(
                      width: _actionsWidth,
                      child: Center(child: _RxHeaderCell('Actions'))),
                ],
              ),
            ),

            // ── Table rows ────────────────────────────────────────────────────
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                      _query.trim().isEmpty
                          ? 'No prescriptions found'
                          : 'No prescriptions match "${_query.trim()}"',
                      style: const TextStyle(color: RxColors.textSecondary)),
                ),
              )
            else if (fill)
              Expanded(
                child: Scrollbar(
                  controller: _rowsScroll,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _rowsScroll,
                    padding: const EdgeInsets.only(right: 12),
                    itemCount: rows.length,
                    itemBuilder: (_, i) => row(rows[i]),
                  ),
                ),
              )
            else
              Column(children: [for (final rx in rows) row(rx)]),
          ],
        ),
      );

      // Inside a patient's profile the tab already sits on the pale panel;
      // on its own page the card gets one, as in the design.
      final padding = widget.patient == null
          ? const EdgeInsets.all(24)
          : const EdgeInsets.all(4);
      final framed = widget.patient == null
          ? Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F5F6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: card,
            )
          : card;

      return Material(
        color: Colors.transparent,
        child: fill
            ? Padding(padding: padding, child: framed)
            : SingleChildScrollView(padding: padding, child: framed),
      );
    });
  }
}

// Column shares of the table.
const _patientFlex = 4;
const _diagnosisFlex = 4;
const _referenceFlex = 3;
const _dateFlex = 3;
const _statusFlex = 3;
const _actionsWidth = 110.0;

/// A white card on the design's teal edge.
class _RxEdgedCard extends StatelessWidget {
  const _RxEdgedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6DD0D8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }
}

/// The pale pill with a teal plus, top right.
class _NewPrescriptionButton extends StatelessWidget {
  const _NewPrescriptionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 3, 18, 3),
        decoration: BoxDecoration(
          color: RxColors.tealLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFF2E9FA5),
              child: Icon(Icons.add, size: 22, color: Colors.black),
            ),
            SizedBox(width: 14),
            Text('New Prescription',
                style: TextStyle(fontSize: 12, color: Color(0xFF2E9FA5))),
          ],
        ),
      ),
    );
  }
}

/// A filter: black when chosen, plain grey text otherwise.
class _RxFilterChip extends StatelessWidget {
  const _RxFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : const Color(0xFF6C6C6C),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────
class _RxHeaderCell extends StatelessWidget {
  const _RxHeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9AA5A6)));
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
    const cell = TextStyle(fontSize: 12, color: Color(0xFF6C6C6C));
    final initials = rx.patientName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onViewDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered
                ? RxColors.tealLight.withValues(alpha: 0.5)
                : Colors.transparent,
            border: const Border(
                bottom: BorderSide(color: Color(0xFFF2F5F5), width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              // Patient: initials on the design's ringed avatar, then name.
              Expanded(
                flex: _patientFlex,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RxColors.tealLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2E9FA5), width: 1.5),
                      ),
                      child: Text(initials,
                          style: const TextStyle(
                              color: Color(0xFF2E9FA5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(rx.patientName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: RxColors.textPrimary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: _diagnosisFlex,
                child: Text(rx.medication,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: cell),
              ),
              Expanded(
                flex: _referenceFlex,
                child: Text(rx.dosage,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
              ),
              Expanded(
                flex: _dateFlex,
                child: Text(rx.dateIssued, style: cell),
              ),
              Expanded(
                flex: _statusFlex,
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
              // Actions: edit, revoke, more.
              SizedBox(
                width: _actionsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // There is no editing a written prescription: the server
                    // has no way to, and a signed one is fixed by law. So the
                    // pencil is shown, as designed, but cannot be used.
                    const _RxIconAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'A written prescription cannot be edited. '
                          'Revoke it and write a new one.',
                    ),
                    // Revoking is the record's delete: it keeps the
                    // prescription but stops it being dispensed.
                    _RxIconAction(
                      icon: Icons.delete_outline,
                      tooltip: widget.onRevoke != null
                          ? 'Revoke prescription'
                          : 'Only a signed prescription not yet dispensed '
                              'can be revoked',
                      onTap: widget.onRevoke,
                    ),
                    _RxIconAction(
                      icon: Icons.more_vert,
                      tooltip: 'More actions',
                      onTap: () => _showMenu(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bare icon in the Actions column; greyed when [onTap] is null.
class _RxIconAction extends StatelessWidget {
  const _RxIconAction({required this.icon, required this.tooltip, this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      iconSize: 18,
      color: RxColors.textPrimary,
      disabledColor: const Color(0xFFC4CCCC),
      icon: Icon(icon),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
/// A solid pill, white text, as in the design.
class _RxStatusBadge extends StatelessWidget {
  const _RxStatusBadge({required this.status});
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
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
      _RxAction(
          label: 'View Details',
          icon: Icons.visibility_outlined,
          onTap: () {
            Navigator.pop(context);
            onViewDetails();
          }),
      if (onCheckInteractions != null)
        _RxAction(
            label: 'Check Interactions',
            icon: Icons.science_outlined,
            onTap: () {
              Navigator.pop(context);
              onCheckInteractions!();
            }),
      // Only offered while the prescription is still unsigned.
      if (onSign != null)
        _RxAction(
            label: 'Sign Prescription',
            icon: Icons.draw_outlined,
            onTap: () {
              Navigator.pop(context);
              onSign!();
            }),
      // Only offered once it is signed and therefore dispensable.
      if (onRevoke != null)
        _RxAction(
            label: 'Revoke Prescription',
            icon: Icons.block_outlined,
            onTap: () {
              Navigator.pop(context);
              onRevoke!();
            }),
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
                        border:
                            Border.all(color: RxColors.textPrimary, width: 1.5),
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
              ? (widget.isDanger ? Colors.red.shade50 : RxColors.tealLight)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon, size: 17, color: color),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight:
                          _hovered ? FontWeight.w500 : FontWeight.w400)),
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

import 'package:flutter/material.dart';
import 'package:pholders_app/features/pharmacy/patients/presentation/patients_screen.dart' show Patient;
import 'package:pholders_app/features/pharmacy/patients/presentation/prescription_details_screen.dart';

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
enum RxStatus { approved, pending, dispensed, expired }

class Prescription {

  const Prescription({
    required this.id,
    required this.patientName,
    required this.medication,
    required this.dosage,
    required this.dateIssued,
    required this.status,
  });
  final String id;
  final String patientName;
  final String medication;
  final String dosage;
  final String dateIssued;
  final RxStatus status;
}

// ─── Mock data ────────────────────────────────────────────────────────────────
List<Prescription> _mockPrescriptions(String patientName) => [
      Prescription(id: 'RX001', patientName: patientName, medication: 'Isotretinoin', dosage: '10mg', dateIssued: '01 Mar', status: RxStatus.approved),
      Prescription(id: 'RX002', patientName: patientName, medication: 'Isotretinoin', dosage: '10mg', dateIssued: '01 Mar', status: RxStatus.approved),
      Prescription(id: 'RX003', patientName: patientName, medication: 'Isotretinoin', dosage: '10mg', dateIssued: '01 Mar', status: RxStatus.approved),
      Prescription(id: 'RX004', patientName: patientName, medication: 'Isotretinoin', dosage: '30mg', dateIssued: '01 Mar', status: RxStatus.approved),
      Prescription(id: 'RX005', patientName: patientName, medication: 'Isotretinoin', dosage: '40mg', dateIssued: '01 Mar', status: RxStatus.pending),
      Prescription(id: 'RX006', patientName: patientName, medication: 'Isotretinoin', dosage: '10mg', dateIssued: '01 Mar', status: RxStatus.approved),
      Prescription(id: 'RX007', patientName: patientName, medication: 'Isotretinoin', dosage: '30mg', dateIssued: '01 Mar', status: RxStatus.dispensed),
      Prescription(id: 'RX008', patientName: patientName, medication: 'Isotretinoin', dosage: '20mg', dateIssued: '01 Mar', status: RxStatus.approved),
    ];

// ─── Prescriptions Screen ─────────────────────────────────────────────────────
class PrescriptionsScreen extends StatefulWidget {

  const PrescriptionsScreen({super.key, required this.patient});
  final Patient patient;

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  int _filterIndex = 0;
  late List<Prescription> _allPrescriptions;
  Prescription? _selectedPrescription; // null = list, non-null = details

  static const _filters = ['All', 'Pending', 'Approved', 'Dispensed', 'Expired'];

  @override
  void initState() {
    super.initState();
    _allPrescriptions = _mockPrescriptions(widget.patient.name);
  }

  List<Prescription> get _filtered {
    if (_filterIndex == 0) return _allPrescriptions;
    final map = {
      1: RxStatus.pending,
      2: RxStatus.approved,
      3: RxStatus.dispensed,
      4: RxStatus.expired,
    };
    return _allPrescriptions.where((p) => p.status == map[_filterIndex]).toList();
  }

  void _addPrescription() async {
    final result = await showDialog<Prescription>(
      context: context,
      builder: (_) => _PrescriptionFormDialog(patientName: widget.patient.name),
    );
    if (result != null) setState(() => _allPrescriptions.add(result));
  }

  void _editPrescription(Prescription rx) async {
    final result = await showDialog<Prescription>(
      context: context,
      builder: (_) => _PrescriptionFormDialog(
          patientName: widget.patient.name, existing: rx),
    );
    if (result != null) {
      setState(() {
        final i = _allPrescriptions.indexWhere((p) => p.id == rx.id);
        if (i != -1) _allPrescriptions[i] = result;
      });
    }
  }

  void _deletePrescription(Prescription rx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Prescription'),
        content: Text('Remove prescription for ${rx.medication}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _allPrescriptions.removeWhere((p) => p.id == rx.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show details screen when a prescription is selected
    if (_selectedPrescription != null) {
      return PrescriptionDetailsScreen(
        prescription: _selectedPrescription!,
        onBack: () => setState(() => _selectedPrescription = null),
      );
    }

    return SingleChildScrollView(
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
                  onPressed: _addPrescription,
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

            // ── Filter tabs ─────────────────────────────────────────────────
            Row(
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
                  Expanded(flex: 3, child: _RxHeaderCell('Medication')),
                  Expanded(flex: 2, child: _RxHeaderCell('Dosage')),
                  Expanded(flex: 2, child: _RxHeaderCell('Date Issued')),
                  Expanded(flex: 2, child: _RxHeaderCell('Status')),
                  Expanded(flex: 2, child: _RxHeaderCell('Actions')),
                ],
              ),
            ),

            // ── Table rows ──────────────────────────────────────────────────
            _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No prescriptions found',
                          style: TextStyle(
                              color: RxColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: _filtered
                        .map((rx) => _RxRow(
                              prescription: rx,
                              onEdit: () => _editPrescription(rx),
                              onDelete: () => _deletePrescription(rx),
                              onViewDetails: () => setState(
                                  () => _selectedPrescription = rx),
                            ))
                        .toList(),
                  ),
          ],
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
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });
  final Prescription prescription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

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
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onViewDetails: widget.onViewDetails,
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
              child: _RxStatusBadge(status: rx.status),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _RxActionBtn(
                      icon: Icons.edit_outlined,
                      onTap: widget.onEdit),
                  const SizedBox(width: 6),
                  _RxActionBtn(
                      icon: Icons.delete_outline,
                      onTap: widget.onDelete),
                  const SizedBox(width: 6),
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
    );
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
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _RxAction(label: 'View Details', icon: Icons.visibility_outlined,
          onTap: () { Navigator.pop(context); onViewDetails(); }),
      _RxAction(label: 'Edit Prescription', icon: Icons.edit_outlined,
          onTap: () { Navigator.pop(context); onEdit(); }),
      _RxAction(label: 'Mark as Dispensed', icon: Icons.check_circle_outline,
          onTap: () => Navigator.pop(context)),
      _RxAction(label: 'Send to Pharmacy', icon: Icons.local_pharmacy_outlined,
          onTap: () => Navigator.pop(context)),
      _RxAction(label: 'Delete', icon: Icons.delete_outline,
          onTap: () { Navigator.pop(context); onDelete(); }),
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

// ─── Add / Edit prescription dialog ──────────────────────────────────────────
class _PrescriptionFormDialog extends StatefulWidget {
  const _PrescriptionFormDialog(
      {required this.patientName, this.existing});
  final String patientName;
  final Prescription? existing;

  @override
  State<_PrescriptionFormDialog> createState() =>
      _PrescriptionFormDialogState();
}

class _PrescriptionFormDialogState
    extends State<_PrescriptionFormDialog> {
  late final TextEditingController _medCtrl;
  late final TextEditingController _dosageCtrl;
  late RxStatus _status;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _medCtrl =
        TextEditingController(text: widget.existing?.medication ?? '');
    _dosageCtrl =
        TextEditingController(text: widget.existing?.dosage ?? '');
    _status = widget.existing?.status ?? RxStatus.pending;
  }

  @override
  void dispose() {
    _medCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_medCtrl.text.isEmpty || _dosageCtrl.text.isEmpty) return;
    final result = Prescription(
      id: widget.existing?.id ??
          'RX${DateTime.now().millisecondsSinceEpoch}',
      patientName: widget.patientName,
      medication: _medCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      dateIssued: '${DateTime.now().day} ${_monthName(DateTime.now().month)}',
      status: _status,
    );
    Navigator.pop(context, result);
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Edit Prescription' : 'New Prescription',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              _RxFormField(
                  label: 'Medication',
                  controller: _medCtrl,
                  hint: 'e.g. Amoxicillin'),
              const SizedBox(height: 14),
              _RxFormField(
                  label: 'Dosage',
                  controller: _dosageCtrl,
                  hint: 'e.g. 500mg'),
              const SizedBox(height: 14),

              const Text('Status',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RxColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<RxStatus>(
                isExpanded: true,
                initialValue: _status,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: RxColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: RxColors.border)),
                ),
                items: RxStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name[0].toUpperCase() +
                            s.name.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RxColors.teal,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          _isEdit ? 'Save Changes' : 'Add Prescription',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RxFormField extends StatelessWidget {

  const _RxFormField(
      {required this.label,
      required this.controller,
      required this.hint});
  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RxColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: RxColors.textSecondary, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: RxColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: RxColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: RxColors.teal, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

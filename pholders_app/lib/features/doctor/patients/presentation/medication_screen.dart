import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart' show Patient;
import 'package:pholders_app/features/doctor/patients/presentation/medication_details_screen.dart';

// ─── Colors (reuse same palette) ─────────────────────────────────────────────
class MedColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const activeBg = Color(0xFFD9F3F3);
  static const stoppedBg = Color(0xFFEEEEEE);
  static const stoppedText = Color(0xFF9E9E9E);
  static const cardBg = Color(0xFFFFFFFF);
  static const darkBadge = Color(0xFF1A2B2B);
  static const criticalRed = Color(0xFFFF6B6B);
}

// ─── Data models ──────────────────────────────────────────────────────────────
class MedicationItem {

  const MedicationItem({
    required this.name,
    required this.dosage,
    required this.startDate,
    required this.endDate,
    required this.adherence,
    required this.prescribedBy,
    required this.isActive,
  });
  final String name;
  final String dosage;
  final String startDate;
  final String endDate;
  final double adherence;
  final String prescribedBy;
  final bool isActive;
}

class MedHistoryItem {

  const MedHistoryItem({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.isActive,
    required this.adherence,
  });
  final String medication;
  final String dosage;
  final String frequency;
  final String duration;
  final bool isActive;
  final int adherence;
}

class MedicalHistoryItem {

  const MedicalHistoryItem({
    required this.icon,
    required this.category,
    required this.value,
  });
  final IconData icon;
  final String category;
  final String value;
}

// ─── Medication Screen ────────────────────────────────────────────────────────
class MedicationScreen extends StatefulWidget {

  const MedicationScreen({super.key, required this.patient});
  final Patient patient;

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  MedHistoryItem? _selectedItem; // null = list, non-null = details

  final _medications = const [
    MedicationItem(
      name: 'Amoxicillin 500mg',
      dosage: '1 capsule, 3x daily',
      startDate: '14 Feb 2026',
      endDate: '14 Feb 2026',
      adherence: 0.85,
      prescribedBy: 'Dr Mokoena',
      isActive: true,
    ),
    MedicationItem(
      name: 'Amoxicillin 500mg',
      dosage: '1 capsule, 3x daily',
      startDate: '14 Feb 2026',
      endDate: '14 Feb 2026',
      adherence: 0.85,
      prescribedBy: 'Dr Mokoena',
      isActive: true,
    ),
  ];

  final _medHistory = const [
    MedHistoryItem(medication: 'Isotretinoin', dosage: '20mg', frequency: 'Once Daily', duration: '30 days', isActive: true, adherence: 85),
    MedHistoryItem(medication: 'Isotretinoin', dosage: '20mg', frequency: 'Once Daily', duration: '30 days', isActive: false, adherence: 85),
    MedHistoryItem(medication: 'Isotretinoin', dosage: '20mg', frequency: 'Once Daily', duration: '30 days', isActive: true, adherence: 85),
    MedHistoryItem(medication: 'Isotretinoin', dosage: '20mg', frequency: 'Once Daily', duration: '30 days', isActive: false, adherence: 85),
  ];

  final _medicalHistory = const [
    MedicalHistoryItem(icon: Icons.monitor_heart_outlined, category: 'Chronic disease', value: 'IHD, Obesity, Chronic thyroid disorder'),
    MedicalHistoryItem(icon: Icons.medical_services_outlined, category: 'Surgery', value: 'Liposuction'),
    MedicalHistoryItem(icon: Icons.warning_amber_outlined, category: 'Related medicational complications', value: 'Nephropathy, Neuphropathy, Sexual dysfuntion'),
    MedicalHistoryItem(icon: Icons.local_hospital_outlined, category: 'Diabetes emergencies', value: 'Diabetic ketoacidos'),
    MedicalHistoryItem(icon: Icons.people_outline_rounded, category: 'Family disease', value: 'Obesity (Father)'),
  ];

  List<MedHistoryItem> get _filteredHistory {
    if (_searchQuery.isEmpty) return _medHistory;
    return _medHistory
        .where((m) => m.medication.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Show details screen when an item is selected
    if (_selectedItem != null) {
      return MedicationDetailsScreen(
        item: _selectedItem!,
        onBack: () => setState(() => _selectedItem = null),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
        children: [
          // Top row: Medications card + Medical history card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildMedicationsCard()),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: _buildMedicalHistoryCard()),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom: Medication history table
          _buildMedHistoryTable(),
        ],
      ),
     ), );
  }

  // ── Medications card ─────────────────────────────────────────────────────────
  Widget _buildMedicationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: MedColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: MedColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Medications',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MedColors.textPrimary)),
              const Spacer(),
              // Active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: MedColors.darkBadge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              // Critical badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: MedColors.criticalRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Critical',
                    style: TextStyle(
                        color: MedColors.criticalRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Medication items
          ..._medications.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MedicationCard(item: m),
              )),
        ],
      ),
    );
  }

  // ── Medical history card ──────────────────────────────────────────────────────
  Widget _buildMedicalHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: MedColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_outlined,
                    color: MedColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Medical history',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MedColors.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Edit',
                    style: TextStyle(color: MedColors.teal, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // History items
          ..._medicalHistory.map((item) => _MedicalHistoryRow(item: item)),
        ],
      ),
    );
  }

    // ── Medication history table ───────────────────────────────────────────────────
  Widget _buildMedHistoryTable() {
    return Container(
      decoration: BoxDecoration(
        color: MedColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: MedColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Medication history',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MedColors.textPrimary)),
              const Spacer(),
              // Search field
              Container(
                width: 220,
                height: 38,
                decoration: BoxDecoration(
                  color: MedColors.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MedColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search medication name...',
                    hintStyle:
                        TextStyle(color: MedColors.textSecondary, fontSize: 12),
                    prefixIcon: Icon(Icons.search,
                        size: 16, color: MedColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Prescribe button
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedColors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text('Prescribe Medication',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: MedColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Medication')),
                Expanded(flex: 2, child: _TableHeader('Dosage')),
                Expanded(flex: 2, child: _TableHeader('Frequency')),
                Expanded(flex: 2, child: _TableHeader('Duration')),
                Expanded(flex: 2, child: _TableHeader('Status')),
                Expanded(flex: 2, child: _TableHeader('Adherence')),
                Expanded(flex: 1, child: _TableHeader('Actions')),
              ],
            ),
          ),

          // Table rows
          ..._filteredHistory.map((item) => _MedHistoryRow(
                item: item,
                onViewDetails: () => setState(() => _selectedItem = item),
              )),
        ],
      ),
    );
  }
}

// ─── Medication card widget ───────────────────────────────────────────────────
class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.item});
  final MedicationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MedColors.textPrimary)),
          const SizedBox(height: 10),
          _MedRow(label: 'Dosage', value: item.dosage),
          const SizedBox(height: 6),
          _MedRow(label: 'Start Date', value: item.startDate),
          const SizedBox(height: 6),
          _MedRow(label: 'End Date', value: item.endDate),
          const SizedBox(height: 10),
          // Adherence + status row
          Row(
            children: [
              const Text('Adherence',
                  style: TextStyle(
                      fontSize: 11, color: MedColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.adherence,
                    backgroundColor: MedColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(MedColors.teal),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('${(item.adherence * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 11, color: MedColors.textSecondary)),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.green),
                  ),
                  const SizedBox(width: 4),
                  const Text('Active',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text('Prescribed by ${item.prescribedBy}',
                      style: const TextStyle(
                          fontSize: 11, color: MedColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  const _MedRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: MedColors.textSecondary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: MedColors.tealLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  color: MedColors.teal,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─── Medical history row ──────────────────────────────────────────────────────
class _MedicalHistoryRow extends StatelessWidget {
  const _MedicalHistoryRow({required this.item});
  final MedicalHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: MedColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category,
                    style: const TextStyle(
                        fontSize: 11, color: MedColors.textSecondary)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MedColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MedColors.textSecondary));
  }
}

// ─── Medication history row ───────────────────────────────────────────────────
class _MedHistoryRow extends StatefulWidget {
  const _MedHistoryRow({required this.item, required this.onViewDetails});
  final MedHistoryItem item;
  final VoidCallback onViewDetails;

  @override
  State<_MedHistoryRow> createState() => _MedHistoryRowState();
}

class _MedHistoryRowState extends State<_MedHistoryRow> {
  bool _hovered = false;

  void _showActionsMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (_) => _MedActionsMenu(onViewDetails: widget.onViewDetails),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? MedColors.tealLight.withValues(alpha: 0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Medication
            Expanded(
              flex: 3,
              child: Text(item.medication,
                  style: const TextStyle(
                      fontSize: 13, color: MedColors.textPrimary)),
            ),
            // Dosage
            Expanded(
              flex: 2,
              child: Text(item.dosage,
                  style: const TextStyle(
                      fontSize: 13, color: MedColors.textSecondary)),
            ),
            // Frequency
            Expanded(
              flex: 2,
              child: Text(item.frequency,
                  style: const TextStyle(
                      fontSize: 13, color: MedColors.textSecondary)),
            ),
            // Duration
            Expanded(
              flex: 2,
              child: Text(item.duration,
                  style: const TextStyle(
                      fontSize: 13, color: MedColors.textSecondary)),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? MedColors.activeBg
                      : MedColors.stoppedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isActive ? 'Active' : 'Stopped',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isActive
                        ? MedColors.teal
                        : MedColors.stoppedText,
                  ),
                ),
              ),
            ),
            // Adherence
            Expanded(
              flex: 2,
              child: Text('${item.adherence}%',
                  style: const TextStyle(
                      fontSize: 13, color: MedColors.textSecondary)),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => _showActionsMenu(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: MedColors.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MedColors.border),
                  ),
                  child: const Icon(Icons.more_vert,
                      size: 16, color: MedColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Med actions menu modal ───────────────────────────────────────────────────
class _MedActionsMenu extends StatelessWidget {
  const _MedActionsMenu({required this.onViewDetails});
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _MedAction(label: 'View Details', icon: Icons.visibility_outlined,
          onTap: () { Navigator.pop(context); onViewDetails(); }),
      _MedAction(label: 'Adjust Medication', icon: Icons.tune_rounded,
          onTap: () => Navigator.pop(context)),
      _MedAction(label: 'Stop Medication', icon: Icons.stop_circle_outlined,
          onTap: () => Navigator.pop(context)),
      _MedAction(label: 'Send Reminder', icon: Icons.notifications_outlined,
          onTap: () => Navigator.pop(context)),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 260,
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
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: MedColors.textPrimary, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: MedColors.textPrimary),
                    ),
                  ),
                ),
              ),
              ...List.generate(actions.length, (i) {
                final isLast = i == actions.length - 1;
                return Column(
                  children: [
                    _MedActionItem(
                      label: actions[i].label,
                      icon: actions[i].icon,
                      onTap: actions[i].onTap,
                    ),
                    if (!isLast)
                      const Divider(height: 1, color: MedColors.border,
                          indent: 16, endIndent: 16),
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

class _MedAction {
  const _MedAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _MedActionItem extends StatefulWidget {
  const _MedActionItem(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_MedActionItem> createState() => _MedActionItemState();
}

class _MedActionItemState extends State<_MedActionItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          color: _hovered ? MedColors.tealLight : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 17,
                  color: _hovered
                      ? MedColors.teal
                      : MedColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: _hovered
                      ? MedColors.teal
                      : MedColors.textPrimary,
                  fontWeight: _hovered
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

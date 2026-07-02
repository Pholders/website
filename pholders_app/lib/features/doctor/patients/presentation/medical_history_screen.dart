import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart' show Patient;

// ─── Colors ───────────────────────────────────────────────────────────────────
class HistColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const cardBg = Color(0xFFFFFFFF);
  static const amber = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFF3DC);
  static const purple = Color(0xFF9B59B6);
  static const purpleLight = Color(0xFFF3E8FF);
  static const blue = Color(0xFF3498DB);
  static const blueLight = Color(0xFFE8F4FD);
  static const green = Color(0xFF4CAF50);
  static const greenLight = Color(0xFFE8F5E9);
  static const red = Color(0xFFFF6B6B);
  static const redLight = Color(0xFFFFEEEE);
}

// ─── History entry type ───────────────────────────────────────────────────────
enum HistoryType { all, prescription, visit, alert, document, note }

extension HistoryTypeExt on HistoryType {
  String get label {
    switch (this) {
      case HistoryType.all: return 'All';
      case HistoryType.prescription: return 'Prescriptions';
      case HistoryType.visit: return 'Visits';
      case HistoryType.alert: return 'Alerts';
      case HistoryType.document: return 'Documents';
      case HistoryType.note: return 'Notes';
    }
  }

  IconData get icon {
    switch (this) {
      case HistoryType.all: return Icons.history_rounded;
      case HistoryType.prescription: return Icons.medication_outlined;
      case HistoryType.visit: return Icons.local_hospital_outlined;
      case HistoryType.alert: return Icons.warning_amber_outlined;
      case HistoryType.document: return Icons.description_outlined;
      case HistoryType.note: return Icons.note_alt_outlined;
    }
  }

  Color get color {
    switch (this) {
      case HistoryType.all: return HistColors.teal;
      case HistoryType.prescription: return HistColors.purple;
      case HistoryType.visit: return HistColors.teal;
      case HistoryType.alert: return HistColors.amber;
      case HistoryType.document: return HistColors.blue;
      case HistoryType.note: return HistColors.green;
    }
  }

  Color get bgColor {
    switch (this) {
      case HistoryType.all: return HistColors.tealLight;
      case HistoryType.prescription: return HistColors.purpleLight;
      case HistoryType.visit: return HistColors.tealLight;
      case HistoryType.alert: return HistColors.amberLight;
      case HistoryType.document: return HistColors.blueLight;
      case HistoryType.note: return HistColors.greenLight;
    }
  }
}

// ─── History entry model ──────────────────────────────────────────────────────
class HistoryEntry {
  final String id;
  final HistoryType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final String? doctor;
  final String? detail;
  final String? status;

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.doctor,
    this.detail,
    this.status,
  });
}

// ─── Medical History Screen ───────────────────────────────────────────────────
class MedicalHistoryScreen extends StatefulWidget {
  final Patient patient;

  const MedicalHistoryScreen({super.key, required this.patient});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  HistoryType _activeFilter = HistoryType.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<HistoryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _seedHistory();
  }

  List<HistoryEntry> _seedHistory() {
    final name = widget.patient.name;
    return [
      HistoryEntry(
        id: '1',
        type: HistoryType.prescription,
        title: 'Prescription Issued',
        subtitle: 'Amoxicillin 500mg — 1 capsule 3x daily',
        date: DateTime(2026, 4, 26),
        doctor: 'Dr Smith',
        status: 'Active',
      ),
      HistoryEntry(
        id: '2',
        type: HistoryType.visit,
        title: 'Follow-up Visit',
        subtitle: 'Treatment of Diabetes — Scheduled',
        date: DateTime(2026, 4, 20),
        doctor: 'Dr Mokoena',
        detail: 'Patient reported improved glucose levels.',
      ),
      HistoryEntry(
        id: '3',
        type: HistoryType.alert,
        title: 'Symptom Reported',
        subtitle: 'Patient reported severe headache and dizziness',
        date: DateTime(2026, 4, 15),
        doctor: 'Dr Smith',
        status: 'Reviewed',
      ),
      HistoryEntry(
        id: '4',
        type: HistoryType.document,
        title: 'Document Uploaded',
        subtitle: 'Blood Test Report — PDF, 1.2 MB',
        date: DateTime(2026, 4, 10),
        doctor: 'Dr Smith',
      ),
      HistoryEntry(
        id: '5',
        type: HistoryType.prescription,
        title: 'Prescription Issued',
        subtitle: 'Isotretinoin 20mg — Once daily',
        date: DateTime(2026, 3, 28),
        doctor: 'Dr Mokoena',
        status: 'Active',
      ),
      HistoryEntry(
        id: '6',
        type: HistoryType.visit,
        title: 'Initial Consultation',
        subtitle: 'Acne Treatment — General checkup',
        date: DateTime(2026, 3, 15),
        doctor: 'Dr Smith',
        detail: 'Diagnosed with moderate acne. Started treatment plan.',
      ),
      HistoryEntry(
        id: '7',
        type: HistoryType.note,
        title: 'Clinical Note Added',
        subtitle: 'Patient tolerating medication well. No side effects observed.',
        date: DateTime(2026, 3, 10),
        doctor: 'Dr Smith',
      ),
      HistoryEntry(
        id: '8',
        type: HistoryType.document,
        title: 'Document Uploaded',
        subtitle: 'Chest X-Ray — DICOM, 4.8 MB',
        date: DateTime(2026, 2, 22),
        doctor: 'Dr Mokoena',
      ),
      HistoryEntry(
        id: '9',
        type: HistoryType.alert,
        title: 'Medication Reminder Sent',
        subtitle: 'Reminder sent for Isotretinoin refill',
        date: DateTime(2026, 2, 14),
        doctor: 'Dr Smith',
        status: 'Sent',
      ),
      HistoryEntry(
        id: '10',
        type: HistoryType.prescription,
        title: 'Prescription Renewed',
        subtitle: 'Isotretinoin 20mg — 30-day renewal',
        date: DateTime(2026, 2, 10),
        doctor: 'Dr Mokoena',
        status: 'Dispensed',
      ),
      HistoryEntry(
        id: '11',
        type: HistoryType.visit,
        title: 'Emergency Visit',
        subtitle: 'Diabetic ketoacidosis — Admitted',
        date: DateTime(2025, 12, 5),
        doctor: 'Dr Smith',
        detail: 'Patient stabilised. Insulin protocol initiated.',
        status: 'Resolved',
      ),
      HistoryEntry(
        id: '12',
        type: HistoryType.note,
        title: 'Clinical Note Added',
        subtitle: 'Referred to ophthalmology for diabetes eye screening.',
        date: DateTime(2025, 12, 1),
        doctor: 'Dr Mokoena',
      ),
      HistoryEntry(
        id: '13',
        type: HistoryType.prescription,
        title: 'Prescription Issued',
        subtitle: 'Metformin 500mg — Twice daily with meals',
        date: DateTime(2025, 11, 18),
        doctor: 'Dr Smith',
        status: 'Stopped',
      ),
      HistoryEntry(
        id: '14',
        type: HistoryType.document,
        title: 'Document Uploaded',
        subtitle: 'HbA1c Lab Result — PDF, 0.9 MB',
        date: DateTime(2025, 11, 10),
        doctor: 'Dr Smith',
      ),
    ];
  }

  List<HistoryEntry> get _filtered {
    return _entries.where((e) {
      final matchesType =
          _activeFilter == HistoryType.all || e.type == _activeFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.subtitle.toLowerCase().contains(q) ||
          (e.doctor?.toLowerCase().contains(q) ?? false);
      return matchesType && matchesSearch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Group entries by date heading (Month Year)
  Map<String, List<HistoryEntry>> _grouped(List<HistoryEntry> entries) {
    final map = <String, List<HistoryEntry>>{};
    for (final e in entries) {
      final key = _groupKey(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _groupKey(DateTime dt) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    // Use month+year as section headers
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  void _viewEntry(HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => _HistoryEntryDialog(
        entry: entry,
        formatDate: _formatDate,
      ),
    );
  }

  void _addNote() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 440,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Clinical Note',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter clinical note...',
                    hintStyle: const TextStyle(
                        color: HistColors.textSecondary,
                        fontSize: 13),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: HistColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: HistColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: HistColors.teal, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, ctrl.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HistColors.teal,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Save Note',
                            style: TextStyle(
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
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _entries.insert(
          0,
          HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: HistoryType.note,
            title: 'Clinical Note Added',
            subtitle: result,
            date: DateTime.now(),
            doctor: 'Dr Smith',
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _grouped(filtered);
    final groupKeys = grouped.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: HistColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HistColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: HistColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: HistColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Medical History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HistColors.textPrimary),
                ),
                const Spacer(),

                // Search bar
                Container(
                  width: 240,
                  height: 38,
                  decoration: BoxDecoration(
                    color: HistColors.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HistColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: TextStyle(
                          color: HistColors.textSecondary,
                          fontSize: 12),
                      prefixIcon: Icon(Icons.search,
                          size: 17,
                          color: HistColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Add note button
                ElevatedButton.icon(
                  onPressed: _addNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HistColors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add,
                      color: Colors.white, size: 18),
                  label: const Text('Add Note',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Browse, review, and manage patient medical history',
              style: TextStyle(
                  fontSize: 13, color: HistColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // ── Filter tabs ──────────────────────────────────────────────────
            Row(
              children: HistoryType.values.map((type) {
                final active = type == _activeFilter;
                final count = type == HistoryType.all
                    ? _entries.length
                    : _entries
                        .where((e) => e.type == type)
                        .length;

                return GestureDetector(
                  onTap: () =>
                      setState(() => _activeFilter = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? HistColors.textPrimary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: active
                              ? HistColors.textPrimary
                              : HistColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : HistColors.textSecondary,
                          ),
                        ),
                        if (count > 0 && type != HistoryType.all) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withOpacity(0.2)
                                  : type.bgColor,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : type.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Timeline grouped by month ─────────────────────────────────
            filtered.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 48,
                              color: HistColors.textSecondary
                                  .withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No history matches your search'
                                : 'No history entries yet',
                            style: const TextStyle(
                                color: HistColors.textSecondary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupKeys.map((key) {
                      final entries = grouped[key]!;
                      return _HistoryGroup(
                        groupLabel: key,
                        entries: entries,
                        formatDate: _formatDate,
                        onView: _viewEntry,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── History group (month section) ───────────────────────────────────────────
class _HistoryGroup extends StatelessWidget {
  final String groupLabel;
  final List<HistoryEntry> entries;
  final String Function(DateTime) formatDate;
  final void Function(HistoryEntry) onView;

  const _HistoryGroup({
    required this.groupLabel,
    required this.entries,
    required this.formatDate,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: HistColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                groupLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HistColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Timeline entries
        ...entries.asMap().entries.map((e) {
          final isLast = e.key == entries.length - 1;
          return _HistoryTimelineItem(
            entry: e.value,
            isLast: isLast,
            formatDate: formatDate,
            onView: () => onView(e.value),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Single timeline item ─────────────────────────────────────────────────────
class _HistoryTimelineItem extends StatefulWidget {
  final HistoryEntry entry;
  final bool isLast;
  final String Function(DateTime) formatDate;
  final VoidCallback onView;

  const _HistoryTimelineItem({
    required this.entry,
    required this.isLast,
    required this.formatDate,
    required this.onView,
  });

  @override
  State<_HistoryTimelineItem> createState() =>
      _HistoryTimelineItemState();
}

class _HistoryTimelineItemState
    extends State<_HistoryTimelineItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.type.color,
                    border: Border.all(
                        color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: e.type.color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: HistColors.border,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Entry card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) =>
                    setState(() => _hovered = true),
                onExit: (_) =>
                    setState(() => _hovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? e.type.bgColor
                        : HistColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hovered
                          ? e.type.color.withOpacity(0.3)
                          : HistColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Type icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: e.type.bgColor,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Icon(e.type.icon,
                            size: 18, color: e.type.color),
                      ),

                      const SizedBox(width: 12),

                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        HistColors.textPrimary,
                                  ),
                                ),
                                if (e.status != null) ...[
                                  const SizedBox(width: 8),
                                  _StatusPill(
                                      status: e.status!,
                                      type: e.type),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              e.subtitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      HistColors.textSecondary),
                            ),
                            if (e.doctor != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                e.doctor!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: HistColors.teal,
                                    fontWeight:
                                        FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Date + View button
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.formatDate(e.date),
                            style: const TextStyle(
                                fontSize: 11,
                                color:
                                    HistColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: widget.onView,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6),
                              decoration: BoxDecoration(
                                color: _hovered
                                    ? HistColors.teal
                                    : HistColors.tealLight,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _hovered
                                      ? Colors.white
                                      : HistColors.teal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String status;
  final HistoryType type;
  const _StatusPill({required this.status, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: type.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: type.color,
        ),
      ),
    );
  }
}

// ─── History entry detail dialog ──────────────────────────────────────────────
class _HistoryEntryDialog extends StatelessWidget {
  final HistoryEntry entry;
  final String Function(DateTime) formatDate;

  const _HistoryEntryDialog({
    required this.entry,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: entry.type.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(entry.type.icon,
                        size: 20, color: entry.type.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(entry.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: HistColors.textPrimary)),
                        Text(entry.type.label,
                            style: TextStyle(
                                fontSize: 12,
                                color: entry.type.color,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (entry.status != null)
                    _StatusPill(
                        status: entry.status!,
                        type: entry.type),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: HistColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: HistColors.border),
              const SizedBox(height: 16),

              // Details
              _HistDetail(label: 'Date', value: formatDate(entry.date)),
              if (entry.doctor != null)
                _HistDetail(label: 'Doctor', value: entry.doctor!),
              _HistDetail(label: 'Description', value: entry.subtitle),
              if (entry.detail != null)
                _HistDetail(label: 'Clinical Notes', value: entry.detail!),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HistColors.teal,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistDetail extends StatelessWidget {
  final String label;
  final String value;
  const _HistDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: HistColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: HistColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HistColors.border),
            ),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: HistColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

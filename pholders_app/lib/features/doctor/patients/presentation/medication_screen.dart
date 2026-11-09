import 'package:flutter/material.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_table.dart'
    show ActionsMenu, ActionsMenuItem;
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;
import 'package:pholders_app/features/doctor/prescriptions/presentation/new_prescription_dialog.dart';

/// The Medication tab of a patient's profile, laid out to the design: their
/// current medications beside their medical history, then every medication on
/// their record as a table.
///
/// Everything comes from the patient's record. The design's adherence
/// figures, "critical" filter and condition categories (chronic disease,
/// surgery, family history) are not recorded anywhere this app can read, so
/// they are left out rather than invented.
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({
    super.key,
    required this.patient,
    this.repository,
    this.height,
  });

  final Patient patient;
  final PatientRecordRepository? repository;

  /// The tab's height. When given, the medication history fills what is
  /// left and scrolls inside itself; without it the card grows with its rows.
  final double? height;

  /// The least [height] worth giving: the cards on top plus a few rows.
  static const minHeight = 600.0;

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  List<PatientMedication> _medications = const [];
  bool _medsLoading = true;
  String? _medsError;

  /// The medication whose details fill the tab, or null for the overview.
  PatientMedication? _selected;

  List<PatientHistoryEntry> _history = const [];
  bool _historyLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _loadHistory();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _medsLoading = true;
      _medsError = null;
    });
    try {
      final rows = await _repo.fetchMedications(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _medications = rows;
        _medsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _medsLoading = false;
        _medsError = e.message;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final rows = await _repo.fetchHistory(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _history = rows;
        _historyLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        _historyError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medications = _MedicationsCard(
      medications: _medications,
      loading: _medsLoading,
      error: _medsError,
      onRetry: _loadMedications,
      onOpen: (m) => setState(() => _selected = m),
    );
    final history = _MedicalHistoryCard(
      entries: _history,
      loading: _historyLoading,
      error: _historyError,
    );

    Widget medicationHistory({bool fill = false}) => _MedicationHistoryCard(
          patient: widget.patient,
          medications: _medications,
          loading: _medsLoading,
          error: _medsError,
          onRetry: _loadMedications,
          now: DateTime.now(),
          onViewDetails: (m) => setState(() => _selected = m),
          fill: fill,
        );

    // A medication chosen from the table: its details take the whole tab.
    final selected = _selected;
    if (selected != null) {
      return Material(
        color: Colors.transparent,
        child: SizedBox(
          height: widget.height,
          child: _MedicationDetails(
            medication: selected,
            stopped: _stopped(selected, DateTime.now()),
            fill: widget.height != null,
            onBack: () => setState(() => _selected = null),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final top = wide
            ? SizedBox(
                height: 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: medications),
                    const SizedBox(width: 14),
                    Expanded(child: history),
                  ],
                ),
              )
            : Column(children: [
                SizedBox(height: 320, child: medications),
                const SizedBox(height: 14),
                SizedBox(height: 320, child: history),
              ]);
        // Given a height on a wide screen, the history card takes what the
        // cards above leave and scrolls its own rows, so the page holds still.
        final fill = wide && widget.height != null;
        return SizedBox(
          height: fill ? widget.height : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              top,
              const SizedBox(height: 14),
              if (fill)
                Expanded(child: medicationHistory(fill: true))
              else
                medicationHistory(),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Look ─────────────────────────────────────────────────────────────────────

const _aqua = Color(0xFF6DD0D8);
const _teal = Color(0xFF2EC4C4);
const _darkTeal = Color(0xFF2E9FA5);
const _paleTeal = Color(0xFFE0F4F5);
const _ink = Color(0xFF1A2B2B);
const _label = Color(0xFF8A8A8A);
const _muted = Color(0xFF6C6C6C);
const _line = Color(0xFFE8F0F0);
const _green = Color(0xFF22C55E);

const _months = [
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

String _day(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// A white card, with the design's curved teal edge on the left when [edged].
class _Card extends StatelessWidget {
  const _Card({required this.child, this.edged = false});
  final Widget child;
  final bool edged;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
    if (!edged) return card;
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: _aqua,
        borderRadius: BorderRadius.circular(22),
      ),
      child: card,
    );
  }
}

/// The icon tile and title at the top of each card.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title, this.trailing});
  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _paleTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _ink),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 17, color: _ink)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.5, color: _label)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
        ),
      );
}

// ─── Medications ──────────────────────────────────────────────────────────────

class _MedicationsCard extends StatefulWidget {
  const _MedicationsCard({
    required this.medications,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
  });

  final List<PatientMedication> medications;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  /// A medication card was clicked: show its details.
  final ValueChanged<PatientMedication> onOpen;

  @override
  State<_MedicationsCard> createState() => _MedicationsCardState();
}

class _MedicationsCardState extends State<_MedicationsCard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (widget.loading) {
      body = const _Spinner();
    } else if (widget.error != null) {
      body = _Message(widget.error!, onRetry: widget.onRetry);
    } else if (widget.medications.isEmpty) {
      body = const _Message(
        'No current medication on the patient\'s record. Prescriptions you '
        'write for them are listed below.',
      );
    } else {
      body = Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.only(right: 12, bottom: 4),
          itemCount: widget.medications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _MedicationTile(
            medication: widget.medications[i],
            onTap: () => widget.onOpen(widget.medications[i]),
          ),
        ),
      );
    }

    return _Card(
      edged: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: Icons.medical_services_outlined,
            title: 'Medications',
            // The record returns only current medication, so this labels
            // the list rather than filtering it.
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.loading || widget.error != null
                    ? 'Active'
                    : 'Active (${widget.medications.length})',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Divider(height: 20, color: _line),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// One medication, drawn as the design's card: name and strength on top,
/// how it is taken and its dates in pale pills, its status on the right and
/// who prescribed it in the corner, over a soft curve.
class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.medication, required this.onTap});
  final PatientMedication medication;

  /// Opens the medication's details.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = medication;
    // The design puts the strength in the title ("Amoxicillin 500mg") and
    // how it is taken in the Dosage pill ("1 capsule, 3x daily").
    final title = [m.name, m.dosage].whereType<String>().join(' ');
    final howTaken = [m.frequency, m.route].whereType<String>().join(', ');

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(label,
                    style: const TextStyle(fontSize: 12, color: _ink)),
              ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 170),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    // A shade deeper than the card's pale curve, with a fine
                    // edge, so the pill reads on both the pale and the white.
                    color: const Color(0xFFCBE9ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB5DEE3)),
                  ),
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4F6466))),
                ),
              ),
            ],
          ),
        );

    final notes = [
      if (m.reason != null) 'For ${m.reason}',
      if (m.notes != null) m.notes!,
    ].join('\n');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              children: [
                // The design's curve: pale teal on the left, white sweeping in
                // from the top right behind the pills.
                const Positioned.fill(
                  child: CustomPaint(painter: _CardCurvePainter()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Tooltip(
                        message: notes,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 19, color: _ink),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                line('Dosage',
                                    howTaken.isEmpty ? '—' : howTaken),
                                line(
                                    'Start Date',
                                    m.startDate == null
                                        ? '—'
                                        : _day(m.startDate!)),
                                line(
                                    'End Date',
                                    m.endDate == null
                                        ? 'Ongoing'
                                        : _day(m.endDate!)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 13,
                                  height: 13,
                                  decoration: const BoxDecoration(
                                      color: _green, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                const Text('Active',
                                    style:
                                        TextStyle(fontSize: 12, color: _ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (m.prescribedBy != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Prescribed by ${m.prescribedBy}',
                            style: const TextStyle(fontSize: 12, color: _ink),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the medication card's background: pale teal on the left and
/// along the bottom, white on the right, split by an S-shaped curve that
/// starts on the top edge, sweeps left to about a third of the way across,
/// and comes back out to the bottom edge near the right.
class _CardCurvePainter extends CustomPainter {
  const _CardCurvePainter();

  static const _pale = Color(0xFFDFF2F5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final pale = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.62, 0)
      // Down and to the left, to the waist of the S.
      ..cubicTo(w * 0.42, h * 0.08, w * 0.30, h * 0.30, w * 0.33, h * 0.55)
      // Then back out to the right, meeting the bottom edge.
      ..cubicTo(w * 0.36, h * 0.80, w * 0.62, h * 0.88, w * 0.82, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(pale, Paint()..color = _pale);
  }

  @override
  bool shouldRepaint(_CardCurvePainter oldDelegate) => false;
}

// ─── Medical history ──────────────────────────────────────────────────────────

/// Diagnoses and visit notes from the patient's record, newest first. The
/// record keeps these rather than a list of conditions by category.
class _MedicalHistoryCard extends StatefulWidget {
  const _MedicalHistoryCard({
    required this.entries,
    required this.loading,
    required this.error,
  });

  final List<PatientHistoryEntry> entries;
  final bool loading;
  final String? error;

  @override
  State<_MedicalHistoryCard> createState() => _MedicalHistoryCardState();
}

class _MedicalHistoryCardState extends State<_MedicalHistoryCard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noted = widget.entries.where((e) => e.notes != null).toList();
    final Widget body;
    if (widget.loading) {
      body = const _Spinner();
    } else if (widget.error != null) {
      body = _Message(widget.error!);
    } else if (noted.isEmpty) {
      body = const _Message(
          'No diagnoses or visit notes on the patient\'s record yet.');
    } else {
      body = Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.only(right: 12),
          itemCount: noted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _HistoryTile(entry: noted[i]),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            icon: Icons.history_edu_outlined,
            title: 'Medical history',
          ),
          const SizedBox(height: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final PatientHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isRx = e.kind == 'prescription';
    final caption = [
      isRx ? 'Diagnosis' : 'Visit note',
      if (e.date != null) _day(e.date!),
      if (e.providerName != null) 'Dr ${e.providerName}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRx ? Icons.monitor_heart_outlined : Icons.event_note_outlined,
            size: 16,
            color: _ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption,
                    style: const TextStyle(fontSize: 10, color: _label)),
                const SizedBox(height: 3),
                Text(e.notes!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Medication history ───────────────────────────────────────────────────────

/// Every medication on the patient's record, one row each, as in the design:
/// what it is, how much, how often, for how long, and whether it is still
/// being taken. With a search on the name and a way to prescribe.
///
/// The design's Adherence column is left out: nothing records whether a
/// patient takes what they were given.
class _MedicationHistoryCard extends StatefulWidget {
  const _MedicationHistoryCard({
    required this.patient,
    required this.medications,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.now,
    required this.onViewDetails,
    this.fill = false,
  });

  final Patient patient;
  final List<PatientMedication> medications;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final DateTime now;
  final ValueChanged<PatientMedication> onViewDetails;

  /// Stretched to a given height, with the rows scrolling inside.
  final bool fill;

  @override
  State<_MedicationHistoryCard> createState() => _MedicationHistoryCardState();
}

class _MedicationHistoryCardState extends State<_MedicationHistoryCard> {
  final _search = TextEditingController();
  String _query = '';
  final _rowsScroll = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _rowsScroll.dispose();
    super.dispose();
  }

  Future<void> _prescribe() async {
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          NewPrescriptionDialog(patientId: int.tryParse(widget.patient.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final rows = widget.medications
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList()
      // Still being taken first, then the most recently started.
      ..sort((a, b) {
        final byStatus = (_stopped(a, widget.now) ? 1 : 0)
            .compareTo(_stopped(b, widget.now) ? 1 : 0);
        if (byStatus != 0) return byStatus;
        return (b.startDate ?? DateTime(0))
            .compareTo(a.startDate ?? DateTime(0));
      });

    final Widget body;
    if (widget.loading) {
      body = const SizedBox(height: 80, child: _Spinner());
    } else if (widget.error != null) {
      body = SizedBox(
          height: 100, child: _Message(widget.error!, onRetry: widget.onRetry));
    } else if (widget.medications.isEmpty) {
      body = const SizedBox(
        height: 80,
        child: _Message("No medication on this patient's record yet."),
      );
    } else if (rows.isEmpty) {
      body =
          SizedBox(height: 80, child: _Message('Nothing matches "$_query".'));
    } else {
      Widget row(PatientMedication m) => _MedRow(
            medication: m,
            stopped: _stopped(m, widget.now),
            onViewDetails: widget.onViewDetails,
          );
      body = widget.fill
          ? Expanded(
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
          : Column(children: [for (final m in rows) row(m)]);
    }

    return _Card(
      edged: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: Icons.medical_services_outlined,
            title: 'Medication history',
            trailing: Row(
              children: [
                SizedBox(
                  width: 230,
                  height: 34,
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search medication name…',
                      hintStyle: const TextStyle(fontSize: 12, color: _label),
                      prefixIcon:
                          const Icon(Icons.search, size: 18, color: _ink),
                      filled: true,
                      fillColor: _paleTeal,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: _prescribe,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(3, 3, 14, 3),
                    decoration: BoxDecoration(
                      color: _paleTeal,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _darkTeal,
                          child: Icon(Icons.add, size: 20, color: Colors.black),
                        ),
                        SizedBox(width: 8),
                        Text('Prescribe Medication',
                            style: TextStyle(fontSize: 12, color: _darkTeal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _MedHeader(),
          const Divider(height: 12, color: _line),
          body,
        ],
      ),
    );
  }
}

/// Stopped once its end date has passed; the record has no other stop.
bool _stopped(PatientMedication m, DateTime now) {
  final end = m.endDate?.toLocal();
  if (end == null) return false;
  final today = DateTime(now.year, now.month, now.day);
  return DateTime(end.year, end.month, end.day).isBefore(today);
}

/// "30 days" from start to end, "Ongoing" with no end, or "Until 3 Dec 2026"
/// when only the end is known.
String _duration(PatientMedication m) {
  final start = m.startDate?.toLocal();
  final end = m.endDate?.toLocal();
  if (end == null) return 'Ongoing';
  if (start == null) return 'Until ${_day(end)}';
  final days = DateTime(end.year, end.month, end.day)
      .difference(DateTime(start.year, start.month, start.day))
      .inDays;
  return days <= 1 ? '1 day' : '$days days';
}

// Column shares of the history table.
const _nameColFlex = 5;
const _dosageColFlex = 3;
const _frequencyColFlex = 4;
const _durationColFlex = 3;
const _statusColFlex = 3;
const _actionsWidth = 56.0;

class _MedHeader extends StatelessWidget {
  const _MedHeader();

  @override
  Widget build(BuildContext context) {
    Widget h(String t) =>
        Text(t, style: const TextStyle(fontSize: 12, color: _label));
    return Row(
      children: [
        Expanded(flex: _nameColFlex, child: h('Medication')),
        Expanded(flex: _dosageColFlex, child: h('Dosage')),
        Expanded(flex: _frequencyColFlex, child: h('Frequency')),
        Expanded(flex: _durationColFlex, child: h('Duration')),
        Expanded(flex: _statusColFlex, child: h('Status')),
        SizedBox(width: _actionsWidth, child: Center(child: h('Actions'))),
      ],
    );
  }
}

/// A medication's actions, as designed.
enum _MedAction {
  viewDetails('View Details'),
  adjust('Adjust Medication'),
  stop('Stop Medication'),
  remind('Send Reminder');

  const _MedAction(this.label);
  final String label;

  /// The backend has no way yet for a doctor to change or stop a medication
  /// on a patient's record, or to message the patient, so those are shown
  /// but cannot be chosen. Allow one here once its endpoint exists, and
  /// handle it in [_MedRow._actions].
  bool get available => this == viewDetails;
}

class _MedRow extends StatelessWidget {
  const _MedRow({
    required this.medication,
    required this.stopped,
    required this.onViewDetails,
  });
  final PatientMedication medication;
  final bool stopped;
  final ValueChanged<PatientMedication> onViewDetails;

  /// The actions card, then whatever was chosen in it.
  Future<void> _actions(BuildContext context) async {
    final action = await showDialog<_MedAction>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => ActionsMenu<_MedAction>(
        width: 300,
        items: [
          for (final a in _MedAction.values)
            ActionsMenuItem(a.label, a, enabled: a.available),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _MedAction.viewDetails:
        onViewDetails(medication);
      case _MedAction.adjust:
      case _MedAction.stop:
      case _MedAction.remind:
        // Not choosable; see [_MedAction.available].
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cell = TextStyle(fontSize: 11, color: _muted);
    final m = medication;
    Widget text(int flex, String? value) => Expanded(
          flex: flex,
          child:
              Text(value ?? '—', overflow: TextOverflow.ellipsis, style: cell),
        );

    return InkWell(
      onTap: () => _actions(context),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            text(_nameColFlex, m.name),
            text(_dosageColFlex, m.dosage),
            text(_frequencyColFlex, m.frequency),
            text(_durationColFlex, _duration(m)),
            Expanded(
              flex: _statusColFlex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(stopped: stopped),
              ),
            ),
            SizedBox(
              width: _actionsWidth,
              child: IconButton(
                tooltip: 'Actions',
                icon: const Icon(Icons.more_vert, size: 20, color: _ink),
                onPressed: () => _actions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Active" in teal, or "Stopped" in grey.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.stopped, this.large = false});
  final bool stopped;

  /// Sized for the details view rather than a table row.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = stopped
        ? (const Color(0xFFD9DCDC), const Color(0xFF9A9FA0), _label)
        : (const Color(0xFFB8E9EC), _darkTeal, _darkTeal);
    return Container(
      width: large ? 104 : 80,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: large ? 6 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(stopped ? 'Stopped' : 'Active',
              style: TextStyle(fontSize: large ? 15 : 12, color: fg)),
        ],
      ),
    );
  }
}

// ─── Medication details ───────────────────────────────────────────────────────

/// One medication, filling the tab, as in the design: each fact in its own
/// read-only box. Opened from the history table's View Details.
///
/// The design's Adherence is left out, as in the table, and so is its edit
/// pencil: there is no way yet for a doctor to change a medication on a
/// patient's record. What else the record holds (route, dates, reason, who
/// prescribed it, notes) follows, when it is there.
class _MedicationDetails extends StatelessWidget {
  const _MedicationDetails({
    required this.medication,
    required this.stopped,
    required this.onBack,
    this.fill = false,
  });

  final PatientMedication medication;
  final bool stopped;
  final VoidCallback onBack;

  /// Given a height, the facts scroll inside the card.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final more = <(String, String?)>[
      ('Route', m.route),
      ('Start date', m.startDate == null ? null : _day(m.startDate!)),
      ('End date', m.endDate == null ? null : _day(m.endDate!)),
      ('Reason', m.reason),
      ('Prescribed by', m.prescribedBy),
      ('Notes', m.notes),
    ].where((f) => f.$2 != null);

    final facts = <Widget>[
      _DetailField('Medication', child: _DetailText(m.name)),
      _DetailField('Dosage', child: _DetailText(m.dosage ?? '—')),
      _DetailField('Frequency', child: _DetailText(m.frequency ?? '—')),
      _DetailField('Duration', child: _DetailText(_duration(m))),
      _DetailField('Status',
          child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(stopped: stopped, large: true))),
      for (final (label, value) in more)
        _DetailField(label, child: _DetailText(value!)),
    ];

    return _Card(
      edged: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _CardTitle(
            icon: Icons.medical_services_outlined,
            title: 'Details',
            trailing: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18, color: _darkTeal),
              label: const Text('Back to medications',
                  style: TextStyle(fontSize: 15, color: _darkTeal)),
            ),
          ),
          const Divider(height: 18, thickness: 1.5, color: _line),
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
    );
  }
}

/// A label over its pale teal box.
class _DetailField extends StatelessWidget {
  const _DetailField(this.label, {required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: _label)),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF3F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFC9E9EC)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SelectableText(text,
      style: const TextStyle(fontSize: 18, color: Color(0xFF6C7A7B)));
}

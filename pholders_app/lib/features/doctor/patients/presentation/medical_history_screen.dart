import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;
import 'package:pholders_app/features/doctor/patients/presentation/record_card.dart';

const _aqua = Color(0xFF6DD0D8);
const _darkTeal = Color(0xFF2E9FA5);
const _paleTeal = Color(0xFFDFF4F6);
const _ink = Color(0xFF1A2B2B);
const _label = Color(0xFF9AA5A6);
const _muted = Color(0xFF6C6C6C);
const _line = Color(0xFFB9D6D8);

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
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The filters above the timeline, as designed. Alerts and notes are not
/// recorded anywhere this app can read, so those two are shown but cannot
/// be chosen.
enum _Filter {
  all('All'),
  prescriptions('Prescriptions'),
  visits('Visits'),
  alerts('Alerts', available: false),
  documents('Documents'),
  notes('Notes', available: false);

  const _Filter(this.label, {this.available = true});
  final String label;
  final bool available;
}

enum _Kind { prescription, visit, document }

/// One point on the timeline: a visit or a prescription from the patient's
/// history, or a file they stored.
class _Event {
  _Event.history(PatientHistoryEntry e)
      : kind = e.kind == 'prescription' ? _Kind.prescription : _Kind.visit,
        date = e.date?.toLocal(),
        history = e,
        document = null;

  _Event.document(PatientDocument d)
      : kind = _Kind.document,
        date = d.uploadedAt?.toLocal(),
        history = null,
        document = d;

  final _Kind kind;
  final DateTime? date;
  final PatientHistoryEntry? history;
  final PatientDocument? document;

  String get title {
    switch (kind) {
      case _Kind.prescription:
        return 'Prescription issued';
      case _Kind.document:
        return 'Document uploaded';
      case _Kind.visit:
        return switch (history?.status) {
          'completed' => 'Visit completed',
          'cancelled' => 'Visit cancelled',
          _ => 'Visit',
        };
    }
  }

  /// The line under the title: the diagnosis or the visit's notes, or the
  /// file's name.
  String? get detail =>
      kind == _Kind.document ? document!.name : history!.notes;
}

/// The History tab of a patient's profile, laid out to the design: a
/// timeline of their visits, prescriptions and stored documents, newest
/// first, grouped by day, with filters and a View on each.
///
/// All of it is the patient's record, read-only. It used to show fourteen
/// invented entries, and "Add note" only added to the list on screen, so a
/// note was gone after a refresh. There is nowhere on the server to keep a
/// doctor's note yet, so none is offered.
class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen(
      {super.key, required this.patient, this.repository});

  final Patient patient;
  final PatientRecordRepository? repository;

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  List<PatientHistoryEntry> _history = const [];
  List<PatientDocument> _documents = const [];
  bool _loading = true;
  String? _error;

  /// Set when the documents could not be read; the history still shows.
  String? _documentsError;

  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _documentsError = null;
    });
    // Both come from the record, fetched once a session.
    final docs = _repo
        .fetchDocuments(widget.patient.id)
        .then<Object>((v) => v, onError: (Object e) => e);
    try {
      final history = await _repo.fetchHistory(widget.patient.id);
      final documents = await docs;
      if (!mounted) return;
      setState(() {
        _history = history;
        if (documents is List<PatientDocument>) {
          _documents = documents;
        } else {
          _documents = const [];
          _documentsError = documents is ApiException
              ? documents.message
              : 'The documents could not be loaded.';
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  List<_Event> get _events {
    final all = [
      for (final e in _history) _Event.history(e),
      for (final d in _documents) _Event.document(d),
    ];
    final kept = all.where((e) => switch (_filter) {
          _Filter.all => true,
          _Filter.prescriptions => e.kind == _Kind.prescription,
          _Filter.visits => e.kind == _Kind.visit,
          _Filter.documents => e.kind == _Kind.document,
          _Filter.alerts || _Filter.notes => false,
        });
    // Newest first; anything undated last.
    return kept.toList()
      ..sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
  }

  @override
  Widget build(BuildContext context) {
    return RecordCard(
      icon: Icons.assignment_outlined,
      title: 'Medical History',
      subtitle: 'Browse, review, and manage patient medical history',
      toolbar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _Filter.values)
              _FilterChip(
                filter: f,
                selected: f == _filter,
                onTap: () => setState(() => _filter = f),
              ),
          ],
        ),
      ),
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _aqua),
          ),
        ),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(fontSize: 13, color: _label)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }

    final events = _events;
    final notes = <Widget>[
      if (_documentsError != null &&
          (_filter == _Filter.all || _filter == _Filter.documents))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Documents: $_documentsError',
              style: const TextStyle(fontSize: 12, color: _label)),
        ),
    ];
    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...notes,
          Text(
            _history.isEmpty && _documents.isEmpty
                ? 'No completed visits or prescriptions on the patient\'s '
                    'record yet.'
                : 'Nothing under ${_filter.label}.',
            style: const TextStyle(fontSize: 13, color: _label),
          ),
        ],
      );
    }

    // Grouped by day, each day under its date.
    final rows = <Widget>[...notes];
    DateTime? shownDay;
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final d = e.date;
      final day = d == null ? null : DateTime(d.year, d.month, d.day);
      if (i == 0 || day != shownDay) {
        rows.add(_DayHeader(day: day, first: i == 0));
        shownDay = day;
      }
      rows.add(_EventRow(
        event: e,
        last: i == events.length - 1,
        onDownload: e.document == null ? null : () => _download(e.document!),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Future<void> _download(PatientDocument doc) async {
    try {
      final bytes = await _repo.downloadDocument(widget.patient.id, doc.id);
      await Printing.sharePdf(bytes: bytes, filename: doc.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _Filter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = filter.available;
    final chip = Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            filter.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : enabled
                      ? _muted
                      : const Color(0xFFC4CCCC),
            ),
          ),
        ),
      ),
    );
    return enabled ? chip : Tooltip(message: 'Not recorded yet', child: chip);
  }
}

/// "Saturday, 26 Dec 2022" over a day's events.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.first});
  final DateTime? day;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final d = day;
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 10, bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, size: 20, color: _ink),
          const SizedBox(width: 10),
          Text(
            d == null
                ? 'Undated'
                : '${_weekdays[d.weekday - 1]}, ${d.day} '
                    '${_months[d.month - 1]} ${d.year}',
            style: const TextStyle(fontSize: 15, color: _label),
          ),
        ],
      ),
    );
  }
}

/// A dot on the line, then the event's card with a View that opens what
/// the record holds on it.
class _EventRow extends StatefulWidget {
  const _EventRow({required this.event, required this.last, this.onDownload});
  final _Event event;
  final bool last;
  final VoidCallback? onDownload;

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final h = e.history;
    final doc = e.document;
    final d = e.date;

    final more = <(String, String)>[
      if (h?.providerName != null) ('Doctor', 'Dr ${h!.providerName}'),
      if (h?.specialization != null) ('Specialty', h!.specialization!),
      if (h?.status != null) ('Status', _sentence(h!.status!)),
      if (doc?.category != null) ('Category', _sentence(doc!.category!)),
      if (doc?.description != null) ('Description', doc!.description!),
      if (doc?.sizeBytes != null) ('Size', _size(doc!.sizeBytes!)),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The timeline: a dot for this event, the line on to the next.
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _aqua,
                    shape: BoxShape.circle,
                    border: Border.all(color: _darkTeal, width: 1.2),
                  ),
                ),
                if (!widget.last)
                  Expanded(child: Container(width: 1.5, color: _line)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: _paleTeal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCDEBEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              if (e.detail != null) ...[
                                const SizedBox(height: 3),
                                Text(e.detail!,
                                    maxLines: _open ? null : 1,
                                    overflow:
                                        _open ? null : TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13, color: _ink)),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                d == null
                                    ? 'No date'
                                    : '${d.day} ${_months[d.month - 1]} '
                                        '${d.year}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _label),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _open = !_open),
                          style: TextButton.styleFrom(
                            foregroundColor: _darkTeal,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(_open ? 'Hide' : 'View',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (_open) ...[
                      const Divider(height: 18, color: Color(0xFFC6E3E6)),
                      if (more.isEmpty && widget.onDownload == null)
                        const Text('Nothing more on the record.',
                            style: TextStyle(fontSize: 13, color: _label)),
                      for (final (label, value) in more)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(label,
                                    style: const TextStyle(
                                        fontSize: 13, color: _label)),
                              ),
                              Expanded(
                                child: Text(value,
                                    style: const TextStyle(
                                        fontSize: 13, color: _ink)),
                              ),
                            ],
                          ),
                        ),
                      if (widget.onDownload != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.onDownload,
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: const Text('Download'),
                            style: TextButton.styleFrom(
                                foregroundColor: _darkTeal),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _sentence(String s) {
    final words = s.replaceAll('_', ' ');
    return words.isEmpty ? s : words[0].toUpperCase() + words.substring(1);
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

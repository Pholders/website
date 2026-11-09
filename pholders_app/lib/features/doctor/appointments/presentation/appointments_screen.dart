import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;

const _aqua = Color(0xFF6DD0D8);
const _darkTeal = Color(0xFF2E9FA5);
const _paleTeal = Color(0xFFE0F4F5);
const _ink = Color(0xFF1A2B2B);
const _label = Color(0xFF8A8A8A);
const _muted = Color(0xFF6C6C6C);
const _line = Color(0xFFE8F0F0);
const _purple = Color(0xFF8E3FB5);
const _purpleBg = Color(0xFFE9E4FB);

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime _dayOf(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

String _short(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)}';

/// The Appointments tab of a patient's profile, laid out to the design: their
/// future and past visits with this doctor on a day, week or month view, and
/// their planned treatments.
///
/// Everything comes from the doctor's own appointments and the patient's
/// record. It used to show three invented visits ("Treatment of diabetes"
/// with "Dr Sam Smith" on 26 Apr 2026) under whichever real patient was open,
/// with fixed counts and a calendar stuck on 15 April.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    required this.patient,
    this.repository,
    this.clock,
  });

  final Patient patient;

  /// Where the planned treatments come from; the app's own by default.
  final PatientRecordRepository? repository;

  /// Stands in for the time of day in tests.
  final DateTime Function()? clock;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

enum _Span { day, week, month }

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _tab = 0; // 0 future, 1 past, 2 planned treatments
  _Span _span = _Span.day;

  /// The day the view is on. Null until the visits are in, then the first
  /// future visit's day (or the last past one's), so the view opens on a
  /// visit rather than an empty day.
  DateTime? _day;

  final _scroll = ScrollController();

  // Planned treatments: the patient's current medication, fetched the first
  // time the tab is opened.
  List<PatientMedication>? _meds;
  String? _medsError;
  bool _medsLoading = false;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMeds() async {
    if (_medsLoading || _meds != null) return;
    setState(() {
      _medsLoading = true;
      _medsError = null;
    });
    try {
      final repo = widget.repository ?? sl<PatientRecordRepository>();
      final rows = await repo.fetchMedications(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _meds = rows;
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

  void _openTab(int tab, _VisitsViewModel vm) {
    setState(() {
      _tab = tab;
      if (tab < 2) _day = _startDay(tab, vm);
    });
    if (tab == 2) _loadMeds();
  }

  DateTime _startDay(int tab, _VisitsViewModel vm) {
    final visits = tab == 0 ? vm.upcoming : vm.past;
    final first = visits.isEmpty ? null : visits.first.date;
    return first == null ? _dayOf(_now) : _dayOf(first);
  }

  void _step(int direction) {
    final d = _day ?? _dayOf(_now);
    setState(() {
      _day = switch (_span) {
        _Span.day => DateTime(d.year, d.month, d.day + direction),
        _Span.week => DateTime(d.year, d.month, d.day + 7 * direction),
        _Span.month => DateTime(d.year, d.month + direction, 1),
      };
    });
  }

  Future<void> _pickDay() async {
    final d = _day ?? _dayOf(_now);
    final picked = await showDatePicker(
      context: context,
      initialDate: d,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _day = _dayOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _VisitsViewModel>(
      distinct: true,
      onInit: (store) {
        if (!store.state.appointmentsState.hasLoadedOnce) {
          store.dispatch(const LoadAppointmentsAction());
        }
      },
      converter: (store) =>
          _VisitsViewModel.of(store.state, widget.patient.id, _now),
      builder: (context, vm) {
        _day ??= vm.loaded ? _startDay(_tab, vm) : null;
        return LayoutBuilder(builder: (context, c) {
          // Given a height, the card fills it and the calendar scrolls
          // inside, under the tabs and the date bar.
          final fill = c.hasBoundedHeight && c.maxHeight >= 360;
          final body = _body(vm, fill);
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: _aqua,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    _tabs(vm),
                    const SizedBox(height: 14),
                    if (_tab < 2 && vm.loaded) ...[
                      _dateBar(),
                      const SizedBox(height: 12),
                    ],
                    if (fill) Expanded(child: body) else body,
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  Widget _tabs(_VisitsViewModel vm) {
    final labels = [
      'Future visits (${vm.upcoming.length})',
      'Past Visits (${vm.past.length})',
      _meds == null
          ? 'Planned Treatments'
          : 'Planned Treatments (${_meds!.length})',
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 40),
            child: InkWell(
              onTap: () => _openTab(i, vm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tab == i ? _darkTeal : _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 74,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _tab == i ? _darkTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Date bar ──────────────────────────────────────────────────────────────

  String _periodLabel(DateTime d) {
    switch (_span) {
      case _Span.day:
        return '${d.day} ${_months[d.month - 1]} ${d.year}';
      case _Span.week:
        final start = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        final end = DateTime(start.year, start.month, start.day + 6);
        return start.month == end.month
            ? '${start.day} – ${end.day} ${_months[end.month - 1]} ${end.year}'
            : '${_short(start)} – ${_short(end)} ${end.year}';
      case _Span.month:
        return '${_months[d.month - 1]} ${d.year}';
    }
  }

  Widget _dateBar() {
    final d = _day ?? _dayOf(_now);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left, color: _muted),
          onPressed: () => _step(-1),
        ),
        IconButton(
          tooltip: 'Next',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right, color: _muted),
          onPressed: () => _step(1),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _periodLabel(d),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, color: _label),
          ),
        ),
        // Day / Week / Month.
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final span in _Span.values)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _span = span),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: _span == span ? _darkTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      switch (span) {
                        _Span.day => 'Day',
                        _Span.week => 'Week',
                        _Span.month => 'Month',
                      },
                      style: TextStyle(
                        fontSize: 13,
                        color: _span == span ? Colors.white : _muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // The day being shown; opens a calendar to choose another.
        Tooltip(
          message: 'Choose a date',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _pickDay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: _muted),
                  const SizedBox(width: 6),
                  Text(_short(d),
                      style: const TextStyle(fontSize: 13, color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _body(_VisitsViewModel vm, bool fill) {
    if (_tab == 2) return _treatments(fill);
    if (vm.loading && !vm.loaded) {
      return const _Message(spinner: true);
    }
    if (vm.error != null && !vm.loaded) return _Message(text: vm.error);

    final visits = _tab == 0 ? vm.upcoming : vm.past;
    if (visits.isEmpty) {
      return _Message(
          text: _tab == 0
              ? 'No upcoming visits with you.'
              : 'No past visits with you yet.');
    }

    final d = _day ?? _dayOf(_now);
    // The next visit is marked out in purple, as in the design.
    final next = vm.upcoming.isEmpty ? null : vm.upcoming.first;
    Widget card(Appointment a) => _VisitCard(
          appointment: a,
          doctorName: vm.doctorName,
          highlighted: identical(a, next),
        );

    final Widget view = switch (_span) {
      _Span.day => _DayView(
          visits: [
            for (final a in visits)
              if (a.date != null && _dayOf(a.date!) == d) a
          ],
          card: card,
        ),
      _Span.week => _DaysList(
          days: [
            for (var i = 0; i < 7; i++)
              DateTime(d.year, d.month, d.day - (d.weekday - 1) + i),
          ],
          visits: visits,
          card: card,
          showEmptyDays: true,
        ),
      _Span.month => _DaysList(
          days: [
            for (var i = 1; i <= DateTime(d.year, d.month + 1, 0).day; i++)
              DateTime(d.year, d.month, i),
          ],
          visits: visits,
          card: card,
          showEmptyDays: false,
        ),
    };

    final scrolling = Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.only(right: 12),
        child: view,
      ),
    );
    return fill ? scrolling : view;
  }

  Widget _treatments(bool fill) {
    if (_medsLoading || (_meds == null && _medsError == null)) {
      return const _Message(spinner: true);
    }
    if (_medsError != null) return _Message(text: _medsError);
    final rows = _meds!;
    if (rows.isEmpty) {
      return const _Message(text: 'No active medication on record.');
    }
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: _paleTeal,
              borderRadius: BorderRadius.circular(6),
              border:
                  const Border(left: BorderSide(color: _darkTeal, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(
                  [
                    m.dosage,
                    m.frequency,
                    m.route,
                    if (m.reason != null) 'for ${m.reason}',
                  ].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
      ],
    );
    return fill
        ? SingleChildScrollView(
            padding: const EdgeInsets.only(right: 12), child: list)
        : list;
  }
}

// ─── Day view ────────────────────────────────────────────────────────────────

/// One row per hour, the visits in their hour. The working day is shown,
/// stretched to take in any visit outside it.
class _DayView extends StatelessWidget {
  const _DayView({required this.visits, required this.card});

  final List<Appointment> visits;
  final Widget Function(Appointment) card;

  static const _rowHeight = 86.0;

  @override
  Widget build(BuildContext context) {
    var first = 8;
    var last = 17;
    for (final a in visits) {
      if (a.hour < first) first = a.hour;
      if (a.hour > last) last = a.hour;
    }

    String hourLabel(int h) {
      final suffix = h < 12 ? 'am' : 'pm';
      final twelve = h % 12 == 0 ? 12 : h % 12;
      return '$twelve $suffix';
    }

    return Column(
      children: [
        for (var h = first; h <= last; h++)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _line, width: 2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(hourLabel(h),
                        style: const TextStyle(fontSize: 13, color: _label)),
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: _rowHeight),
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: _line, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in visits)
                          if (a.hour == h)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: card(a),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Week and month views ────────────────────────────────────────────────────

/// The visits day by day. A week shows every day, saying which are free; a
/// month only the days with a visit.
class _DaysList extends StatelessWidget {
  const _DaysList({
    required this.days,
    required this.visits,
    required this.card,
    required this.showEmptyDays,
  });

  final List<DateTime> days;
  final List<Appointment> visits;
  final Widget Function(Appointment) card;
  final bool showEmptyDays;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final day in days) {
      final those = [
        for (final a in visits)
          if (a.date != null && _dayOf(a.date!) == day) a
      ]..sort((a, b) => (a.timeSlot ?? '').compareTo(b.timeSlot ?? ''));
      if (those.isEmpty && !showEmptyDays) continue;
      rows.add(Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _line, width: 2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weekdays[day.weekday - 1],
                      style: const TextStyle(fontSize: 13, color: _label)),
                  Text(_short(day),
                      style: const TextStyle(fontSize: 13, color: _ink)),
                ],
              ),
            ),
            Expanded(
              child: those.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('No visits',
                          style: TextStyle(fontSize: 12, color: _label)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in those)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: card(a),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ));
    }
    if (rows.isEmpty) {
      return const _Message(text: 'No visits this month.');
    }
    return Column(children: rows);
  }
}

// ─── Visit card ──────────────────────────────────────────────────────────────

/// Time and date, then the service, the doctor and the status, split by
/// thin rules, as in the design.
class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.appointment,
    required this.doctorName,
    required this.highlighted,
  });

  final Appointment appointment;
  final String? doctorName;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final a = appointment;

    Widget cell(String label, Widget value, {double width = 130}) => SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: _label)),
              const SizedBox(height: 4),
              value,
            ],
          ),
        );
    Widget rule() => Container(
          width: 1.2,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: const Color(0xFFB9CFD1),
        );
    const valueStyle = TextStyle(fontSize: 12, color: _ink);

    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: highlighted ? _purpleBg : _paleTeal,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: highlighted ? _purple : _darkTeal, width: 3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a.timeRange.isEmpty ? 'No time set' : a.timeRange,
                      style: const TextStyle(fontSize: 13, color: _label)),
                  const SizedBox(height: 2),
                  Text(a.formattedDate,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ],
              ),
            ),
            rule(),
            cell(
              'Service',
              Text(a.reason ?? 'Consultation',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle),
            ),
            rule(),
            cell(
              'Doctor',
              Text(doctorName ?? 'You',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle),
            ),
            rule(),
            cell(
              'Status',
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _aqua,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(a.statusLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
              width: 120,
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({this.text, this.spinner = false});
  final String? text;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: spinner
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _aqua),
              )
            : Text(text ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _label)),
      ),
    );
  }
}

// ─── Store bindings ──────────────────────────────────────────────────────────

class _VisitsViewModel {
  const _VisitsViewModel({
    required this.upcoming,
    required this.past,
    required this.loading,
    required this.loaded,
    required this.doctorName,
    this.error,
  });

  /// Only this patient's visits, split the way the Appointments page splits
  /// them: past = completed or an earlier day. Future visits run soonest
  /// first, past ones latest first.
  factory _VisitsViewModel.of(AppState state, String patientId, DateTime now) {
    final s = state.appointmentsState;
    final auth = state.authState;
    final mine =
        s.appointments.where((a) => '${a.patientId}' == patientId).toList();
    final far = DateTime(9999);
    int byDate(Appointment a, Appointment b) {
      final c = (a.date ?? far).compareTo(b.date ?? far);
      return c != 0 ? c : (a.timeSlot ?? '').compareTo(b.timeSlot ?? '');
    }

    final upcoming = mine.where((a) => !a.isPastAt(now)).toList()..sort(byDate);
    final past = mine.where((a) => a.isPastAt(now)).toList()
      ..sort((a, b) => byDate(b, a));
    return _VisitsViewModel(
      upcoming: upcoming,
      past: past,
      loading: s.isLoading,
      loaded: s.hasLoadedOnce,
      error: s.errorMessage,
      // Every visit here is with the signed-in doctor.
      doctorName: auth.doctor?.displayName ??
          (auth.userName == null ? null : 'Dr ${auth.userName}'),
    );
  }

  final List<Appointment> upcoming;
  final List<Appointment> past;
  final bool loading;
  final bool loaded;
  final String? error;
  final String? doctorName;

  @override
  bool operator ==(Object other) =>
      other is _VisitsViewModel &&
      _same(other.upcoming, upcoming) &&
      _same(other.past, past) &&
      other.loading == loading &&
      other.loaded == loaded &&
      other.error == error &&
      other.doctorName == doctorName;

  @override
  int get hashCode => Object.hash(
      upcoming.length, past.length, loading, loaded, error, doctorName);

  static bool _same(List<Appointment> a, List<Appointment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

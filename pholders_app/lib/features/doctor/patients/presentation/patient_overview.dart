import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../../dashboard/data/dashboard_summary.dart' as summary;
import '../data/patient_record_repository.dart';
import 'patients_screen.dart' show Patient;

/// The "Patient profile" tab, laid out to the design: a card with who the
/// patient is and their latest vitals, then their visits beside a timeline.
///
/// The design's gender, age, blood group, department and bed number are not
/// recorded anywhere this app can read, so their places hold what is: the
/// patient's contact details and what their bookings say. The vitals are
/// shown as recorded, with when; nothing labels a reading normal or not, as
/// the SRS keeps clinical judgement out of scope.
class PatientOverview extends StatefulWidget {
  const PatientOverview({
    super.key,
    required this.patient,
    this.repository,
    this.clock,
    this.height,
    this.framed = true,
  });

  /// Draws its own pale teal panel. False when it already sits on one, as
  /// on the profile page, whose panel holds the tabs too.
  final bool framed;

  /// The whole overview's height. When given, on a wide screen the visit
  /// and timeline panels stretch to take whatever the profile card leaves.
  /// Without it they keep [_panelHeight].
  final double? height;

  /// The least [height] worth giving: the card plus panels of a usable size.
  static const minHeight = 640.0;

  final Patient patient;
  final PatientRecordRepository? repository;

  /// Stands in for the time of day in tests.
  final DateTime Function()? clock;

  @override
  State<PatientOverview> createState() => _PatientOverviewState();
}

/// One part of the patient's record, as it arrives.
class _Load<T> {
  const _Load.loading()
      : value = null,
        error = null;
  const _Load.done(T this.value) : error = null;
  const _Load.failed(String this.error) : value = null;

  final T? value;
  final String? error;
  bool get isLoading => value == null && error == null;
}

class _PatientOverviewState extends State<PatientOverview> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  _Load<List<PatientVital>> _vitals = const _Load.loading();
  _Load<List<PatientHistoryEntry>> _history = const _Load.loading();
  _Load<List<PatientMedication>> _medications = const _Load.loading();

  @override
  void initState() {
    super.initState();
    final id = widget.patient.id;
    _fetch(() => _repo.fetchVitals(id), (v) => _vitals = v);
    _fetch(() => _repo.fetchHistory(id), (v) => _history = v);
    _fetch(() => _repo.fetchMedications(id), (v) => _medications = v);
  }

  Future<void> _fetch<T>(
    Future<T> Function() call,
    void Function(_Load<T>) set,
  ) async {
    _Load<T> result;
    try {
      result = _Load.done(await call());
    } on ApiException catch (e) {
      result = _Load.failed(e.message);
    } catch (_) {
      result = const _Load.failed('Could not be loaded.');
    }
    if (mounted) setState(() => set(result));
  }

  @override
  Widget build(BuildContext context) {
    final patientId = int.tryParse(widget.patient.id);
    return StoreConnector<AppState, _OverviewViewModel>(
      onInit: (store) => store.dispatch(const LoadAppointmentsAction()),
      converter: (store) {
        final auth = store.state.authState;
        final mine = store.state.appointmentsState.appointments
            .where((a) => patientId != null && a.patientId == patientId)
            .toList();
        return _OverviewViewModel(
          appointments: mine,
          allAppointments: store.state.appointmentsState.appointments,
          doctorName: auth.doctor?.displayName ??
              (auth.userName == null ? null : 'Dr ${auth.userName}'),
        );
      },
      builder: (context, vm) {
        final now = widget.clock?.call() ?? DateTime.now();
        final status = patientId == null
            ? null
            : summary.patientStatus(vm.allAppointments, patientId, now);

        final top = _ProfileCard(
          patient: widget.patient,
          appointments: vm.appointments,
          status: status,
          now: now,
          vitals: _vitals,
        );
        final visits = _VisitsPanel(
          appointments: vm.appointments,
          medications: _medications,
          doctorName: vm.doctorName,
          now: now,
        );
        final timeline = _TimelinePanel(history: _history);

        return LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final fill = wide && widget.height != null;
          final panels = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: visits),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: timeline),
            ],
          );
          return Container(
            height: fill ? widget.height : null,
            // Lined up with the tabs above it on the panel.
            padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
            decoration: widget.framed
                ? BoxDecoration(
                    color: _panelBg,
                    borderRadius: BorderRadius.circular(24),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                top,
                const SizedBox(height: 14),
                if (fill)
                  Expanded(child: panels)
                else if (wide)
                  SizedBox(height: _panelHeight, child: panels)
                else ...[
                  SizedBox(height: _panelHeight, child: visits),
                  const SizedBox(height: 14),
                  SizedBox(height: _panelHeight, child: timeline),
                ],
              ],
            ),
          );
        });
      },
    );
  }
}

class _OverviewViewModel {
  const _OverviewViewModel({
    required this.appointments,
    required this.allAppointments,
    required this.doctorName,
  });

  /// This patient's bookings with the signed-in doctor.
  final List<Appointment> appointments;
  final List<Appointment> allAppointments;
  final String? doctorName;
}

// ─── Look ─────────────────────────────────────────────────────────────────────

/// The visit and timeline panels' height when they are not stretched.
const _panelHeight = 330.0;

const _panelBg = Color(0xFFE3F5F6);
const _aqua = Color(0xFF6DD0D8);
const _teal = Color(0xFF2EC4C4);
const _darkTeal = Color(0xFF2E9FA5);
const _ink = Color(0xFF1A2B2B);
const _label = Color(0xFF8A8A8A);
const _muted = Color(0xFF6C6C6C);
const _purple = Color(0xFF9B59B6);
const _purpleBg = Color(0xFFEDE6F7);
const _visitBg = Color(0xFFDDF1F2);
const _problem = Color(0xFFE5484D);

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

String _date(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _longDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime? _day(Appointment a) {
  final d = a.date?.toLocal();
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

int _byWhen(Appointment a, Appointment b) {
  final da = _day(a), db = _day(b);
  if (da == null || db == null) return da == null ? 1 : -1;
  final c = da.compareTo(db);
  return c != 0
      ? c
      : summary.startMinutes(a).compareTo(summary.startMinutes(b));
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.patient,
    required this.appointments,
    required this.status,
    required this.now,
    required this.vitals,
  });

  final Patient patient;
  final List<Appointment> appointments;
  final summary.PatientStatus? status;
  final DateTime now;
  final _Load<List<PatientVital>> vitals;

  @override
  Widget build(BuildContext context) {
    final held = appointments.where((a) => a.status != 'cancelled').toList()
      ..sort(_byWhen);
    final today = DateTime(now.year, now.month, now.day);
    final past = held.where((a) => a.isPastAt(now)).toList();
    final ahead = held
        .where((a) => !a.isPastAt(now) && !(_day(a)?.isBefore(today) ?? true))
        .toList();
    final first = held.isEmpty ? null : held.first.date;
    final lastReason =
        past.reversed.map((a) => a.reason).whereType<String>().firstOrNull;
    final patientId = int.tryParse(patient.id);
    final lastVisit = patientId == null
        ? null
        : summary.lastVisit(appointments, patientId, now);

    final statusLabel = switch (status) {
      summary.PatientStatus.awaitingAcceptance => 'Awaiting acceptance',
      summary.PatientStatus.visitToday => 'Visit today',
      summary.PatientStatus.upcomingVisit => 'Upcoming visit',
      summary.PatientStatus.seen => 'Seen',
      null => '—',
    };

    // Both halves stand as tall as the taller one, as in the design.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The photo side, on the teal edge the design curves around.
          Container(
            // Wide enough for an email address on one line.
            width: 360,
            decoration: BoxDecoration(
              color: _aqua,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFD3EEF0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Photo(patient: patient),
                  const SizedBox(height: 22),
                  Text(
                    patient.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // One line; an unusually long address scrolls rather than
                  // breaking mid-word.
                  SelectableText(
                    patient.email ?? 'No email on file',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _muted,
                      decoration: TextDecoration.underline,
                      decorationColor: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 26, 28, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoGrid(fields: [
                    ('Phone', patient.phone ?? 'Not given'),
                    ('Patient ID', '#${patient.id.padLeft(5, '0')}'),
                    ('Status', statusLabel),
                    ('Patient since', _date(first)),
                    ('Visits', '${past.length}'),
                    // As on the dashboard and the patients list: the latest
                    // day up to today. A consultation completed early still
                    // carries its later booked day, and showed as a last
                    // visit in the future.
                    (
                      'Last visit',
                      _date(lastVisit)
                    ),
                    (
                      'Next visit',
                      _date(ahead.isEmpty ? null : ahead.first.date)
                    ),
                    ('Last reason for visit', lastReason ?? '—'),
                  ]),
                  const SizedBox(height: 18),
                  const Text('Vitals',
                      style: TextStyle(fontSize: 14, color: _label)),
                  const SizedBox(height: 10),
                  _VitalsStrip(vitals: vitals),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        patient.avatarInitials ?? '?',
        style: const TextStyle(
            fontSize: 34, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: _darkTeal,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _darkTeal, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.5),
        child: patient.avatarUrl == null
            ? fallback
            : Image.network(
                patient.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.fields});
  final List<(String, String)> fields;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    Widget cell((String, String) field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.$1, style: const TextStyle(fontSize: 14, color: _label)),
            const SizedBox(height: 10),
            Text(
              field.$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ],
        );

    // Plain rows rather than a measured Wrap, so the card can be sized to
    // its content.
    return Column(
      children: [
        for (var start = 0; start < fields.length; start += _columns)
          Padding(
            padding: EdgeInsets.only(top: start == 0 ? 0 : 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start; i < start + _columns; i++) ...[
                  if (i > start) const SizedBox(width: 16),
                  Expanded(
                    child: i < fields.length
                        ? cell(fields[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _VitalsStrip extends StatelessWidget {
  const _VitalsStrip({required this.vitals});
  final _Load<List<PatientVital>> vitals;

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
      color: const Color(0xFFF4FAFA),
      borderRadius: BorderRadius.circular(14),
    );
    if (vitals.isLoading) {
      return Container(
        height: 64,
        decoration: box,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
        ),
      );
    }
    if (vitals.error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: box,
        child: Text('Vitals: ${vitals.error}',
            style: const TextStyle(fontSize: 12, color: _problem)),
      );
    }

    // The newest reading of each, as readings need not include all four.
    final rows = vitals.value!;
    T? latest<T>(T? Function(PatientVital) pick) {
      for (final r in rows) {
        if (pick(r) != null) return pick(r);
      }
      return null;
    }

    DateTime? takenFor(Object? Function(PatientVital) pick) {
      for (final r in rows) {
        if (pick(r) != null) return r.measuredAt;
      }
      return null;
    }

    String num1(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    final weight = latest((r) => r.weightKg);
    final glucose = latest((r) => r.bloodGlucose);
    final tiles = [
      _VitalTile(
        icon: Icons.water_drop_outlined,
        label: 'Blood Pressure',
        value: latest((r) => r.bloodPressure),
        unit: 'mmHg',
        taken: takenFor((r) => r.bloodPressure),
      ),
      _VitalTile(
        icon: Icons.monitor_heart_outlined,
        label: 'Heart Rate',
        value: latest((r) => r.heartRate)?.toString(),
        unit: 'bpm',
        taken: takenFor((r) => r.heartRate),
      ),
      _VitalTile(
        icon: Icons.monitor_weight_outlined,
        label: 'Body Weight',
        value: weight == null ? null : num1(weight),
        unit: 'kg',
        taken: takenFor((r) => r.weightKg),
      ),
      _VitalTile(
        icon: Icons.bloodtype_outlined,
        label: 'Blood Glucose',
        value: glucose == null ? null : num1(glucose),
        unit: 'mmol/L',
        taken: takenFor((r) => r.bloodGlucose),
      ),
    ];

    // As in the design: the readings sit on the white card, held by a
    // curved aqua edge on the left.
    return Container(
      padding: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: _aqua,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0xFFD9E6E6),
                ),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.taken,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String unit;
  final DateTime? taken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFD3EEF0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: _darkTeal),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: value ?? '—',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  if (value != null)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(fontSize: 10, color: _label),
                    ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          taken == null ? 'Not recorded' : 'Taken ${_date(taken)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _darkTeal),
        ),
      ],
    );
  }
}

// ─── Visits ───────────────────────────────────────────────────────────────────

class _VisitsPanel extends StatefulWidget {
  const _VisitsPanel({
    required this.appointments,
    required this.medications,
    required this.doctorName,
    required this.now,
  });

  final List<Appointment> appointments;
  final _Load<List<PatientMedication>> medications;
  final String? doctorName;
  final DateTime now;

  @override
  State<_VisitsPanel> createState() => _VisitsPanelState();
}

class _VisitsPanelState extends State<_VisitsPanel> {
  int _tab = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.appointments.toList()..sort(_byWhen);
    final future = all.where((a) => !a.isPastAt(widget.now)).toList();
    final past =
        all.where((a) => a.isPastAt(widget.now)).toList().reversed.toList();
    final meds = widget.medications.value;

    final tabs = [
      'Future visits (${future.length})',
      'Past Visits (${past.length})',
      meds == null
          ? 'Planned Treatments'
          : 'Planned Treatments (${meds.length})',
    ];

    final Widget list;
    if (_tab == 2) {
      list = _treatments();
    } else {
      final visits = _tab == 0 ? future : past;
      list = visits.isEmpty
          ? _Empty(_tab == 0
              ? 'No upcoming visits with you.'
              : 'No past visits with you yet.')
          : Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.only(right: 12),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _VisitCard(
                  appointment: visits[i],
                  doctorName: widget.doctorName,
                  // The design marks the next visit out in purple.
                  highlighted: _tab == 0 && i == 0,
                ),
              ),
            );
    }

    final n = widget.now;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: InkWell(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tab == i ? _darkTeal : Colors.transparent,
                            width: 5,
                          ),
                        ),
                      ),
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _tab == i ? _darkTeal : _label,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: _ink),
              const SizedBox(width: 8),
              Text(
                'Today, ${_weekdays[n.weekday - 1]} ${_longDate(n)}',
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: list),
        ],
      ),
    );
  }

  Widget _treatments() {
    final meds = widget.medications;
    if (meds.isLoading) return const _Spinner();
    if (meds.error != null) return _Empty(meds.error!, problem: true);
    final rows = meds.value!;
    if (rows.isEmpty) return const _Empty('No active medication on record.');
    return ListView.separated(
      padding: const EdgeInsets.only(right: 12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = rows[i];
        final detail =
            [m.dosage, m.frequency, m.route].whereType<String>().join(' · ');
        final span = m.startDate == null && m.endDate == null
            ? null
            : '${_date(m.startDate)} – '
                '${m.endDate == null ? 'ongoing' : _date(m.endDate)}';
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: _visitBg,
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: _darkTeal, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(detail,
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ],
              if (span != null || m.reason != null) ...[
                const SizedBox(height: 3),
                Text(
                  [if (span != null) span, if (m.reason != null) m.reason!]
                      .join(' · '),
                  style: const TextStyle(fontSize: 11, color: _label),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

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
    Widget column(String label, String value, {int flex = 1}) => Expanded(
          flex: flex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: _label)),
              const SizedBox(height: 4),
              Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
            ],
          ),
        );
    Widget rule() => Container(
          width: 1,
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFF9FB2B4),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: highlighted ? _purpleBg : _visitBg,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: highlighted ? _purple : _darkTeal, width: 4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.timeRange.isEmpty ? '—' : a.timeRange,
                    style: const TextStyle(fontSize: 14, color: _muted)),
                const SizedBox(height: 3),
                Text(a.formattedDate,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ],
            ),
          ),
          rule(),
          column('Service', a.reason ?? 'Consultation', flex: 3),
          rule(),
          column('Doctor', doctorName ?? 'You', flex: 3),
          rule(),
          SizedBox(
            width: 112,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status',
                    style: TextStyle(fontSize: 14, color: _label)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: a.status == 'cancelled'
                        ? const Color(0xFFBDBDBD)
                        : _teal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    a.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _TimelinePanel extends StatefulWidget {
  const _TimelinePanel({required this.history});
  final _Load<List<PatientHistoryEntry>> history;

  @override
  State<_TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<_TimelinePanel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.history;
    final Widget body;
    if (h.isLoading) {
      body = const _Spinner();
    } else if (h.error != null) {
      body = _Empty(h.error!, problem: true);
    } else if (h.value!.isEmpty) {
      body = const _Empty('Nothing on their record yet.');
    } else {
      final rows = h.value!;
      body = Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.only(right: 12),
          itemCount: rows.length,
          itemBuilder: (_, i) =>
              _TimelineRow(entry: rows[i], last: i == rows.length - 1),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _panelBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    size: 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              const Text('Timeline',
                  style: TextStyle(fontSize: 22, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE3ECEC)),
          const SizedBox(height: 14),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});
  final PatientHistoryEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final d = entry.date;
    final isRx = entry.kind == 'prescription';
    final title = entry.notes ?? (isRx ? 'Prescription' : 'Visit');
    final sub = [
      isRx ? 'Prescription' : 'Visit',
      if (entry.providerName != null) 'Dr ${entry.providerName}',
      if (entry.specialization != null) entry.specialization!,
    ].join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d == null ? '—' : _months[d.month - 1],
                    style: const TextStyle(fontSize: 13, color: _ink)),
                if (d != null)
                  Text('${d.year}',
                      style: const TextStyle(fontSize: 12, color: _label)),
              ],
            ),
          ),
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: _darkTeal, shape: BoxShape.circle),
                ),
                if (!last)
                  Expanded(
                    child:
                        Container(width: 1.2, color: const Color(0xFFB9D6D8)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                  const SizedBox(height: 3),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _label)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small parts ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.problem = false});
  final String message;
  final bool problem;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: problem ? _problem : _label),
          ),
        ),
      );
}

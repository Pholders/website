import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/utils/greeting.dart';
import '../../../../shared/widgets/doctor_search_scope.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../../appointments/redux/appointments_state.dart';
import '../../patients/data/doctor_patient.dart';
import '../../reviews/redux/reviews_actions.dart';
import '../../reviews/redux/reviews_state.dart';
import '../data/dashboard_summary.dart';
import '../../patients/presentation/patient_table.dart';

/// The doctor's home: today's appointments, what is waiting on them, how busy
/// they have been, and the patients they saw most recently. Laid out to the
/// Figma "Dashboard" frame.
///
/// All of it is worked out from the doctor's own appointments, the list the
/// Appointments and Patients pages load. It used to be invented: four
/// "Maria Wilson" appointments on 14 March, a "72 appointments, +12%" tile,
/// a medication alert about a made-up patient, a fixed chart, and a patient
/// table with conditions, statuses and priorities nobody recorded, whose add,
/// edit and delete changed only the screen. The table keeps the design's
/// columns where there is data for them: the last reason for a visit stands
/// in for Condition, and Status says what the appointments do.
/// How the header greets the doctor: "Dr. Thandi Nkosi", or "Doctor" before
/// a name is known. A name that already carries "Dr" or "Dr." keeps one.
String greetingName(String? name) {
  final bare = (name ?? '')
      .trim()
      .replaceFirst(RegExp(r'^dr\.?\s+', caseSensitive: false), '')
      .trim();
  return bare.isEmpty ? 'Doctor' : 'Dr. $bare';
}

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key, this.clock});

  /// Stands in for the time of day in tests.
  final DateTime Function()? clock;

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  TrendPeriod selectedTrend = TrendPeriod.monthly;

  /// The patient table's filter, the same ones the Patients page offers.
  PatientFilter patientFilter = PatientFilter.all;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  // ─── Palette from the design ──────────────────────────────────────────────
  static const Color aqua = Color(0xFF6DD0D8);
  static const Color darkTeal = Color(0xFF2E9FA5);
  static const Color panelBg = Color(0xFFE3F5F6);
  static const Color mint = Color(0xFFE0F4F5);
  static const Color lavender = Color(0xFFE9E4FB);
  static const Color muted = Color(0xFF7C8B8D);
  static const Color faint = Color(0xFF9AA7A9);
  static const Color orange = Color(0xFFFFA51E);

  static const _months = [
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
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  void _refresh(Store<AppState> store) {
    store.dispatch(const LoadAppointmentsAction());
    // The reviews routes carry no role guard, so the doctor's own id has to
    // be passed rather than inferred from the token.
    final doctorId = store.state.authState.doctor?.id;
    if (doctorId != null && doctorId > 0) {
      store.dispatch(LoadRatingSummaryAction(doctorId: doctorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppointmentsState>(
      onInit: _refresh,
      converter: (store) => store.state.appointmentsState,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final height =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 720.0;

          final compact = width < 860;
          const outer = EdgeInsets.fromLTRB(31, 0, 38, 26);
          final shouldScroll = compact || height < 700;
          final panelHeight = math.max(height, 700.0) - outer.vertical;

          final dashboardPanel = Container(
            padding: const EdgeInsets.fromLTRB(25, 32, 33, 18),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(32),
            ),
            child: compact
                ? _compactLayout(state)
                : SizedBox(
                    height: panelHeight - 50, child: _desktopLayout(state)),
          );

          return Container(
            color: Colors.white,
            padding: compact ? const EdgeInsets.fromLTRB(8, 0, 8, 8) : outer,
            child: shouldScroll
                ? SingleChildScrollView(child: dashboardPanel)
                : SizedBox(
                    height: height - outer.vertical,
                    width: double.infinity,
                    child: dashboardPanel,
                  ),
          );
        },
      ),
    );
  }

  Widget _desktopLayout(AppointmentsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _headerRow(state),
        ),
        const SizedBox(height: 19),
        Expanded(
          flex: 486,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 306, child: _appointmentsSection(state)),
              const SizedBox(width: 27),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 157, child: _statsRow(state)),
                    const SizedBox(height: 12),
                    Expanded(child: _activitySection(state)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(flex: 255, child: _patientsSection(state)),
      ],
    );
  }

  Widget _compactLayout(AppointmentsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(state),
        const SizedBox(height: 16),
        SizedBox(height: 360, child: _appointmentsSection(state)),
        const SizedBox(height: 14),
        SizedBox(height: 157, child: _statsRow(state)),
        const SizedBox(height: 14),
        SizedBox(height: 280, child: _activitySection(state)),
        const SizedBox(height: 14),
        SizedBox(height: 300, child: _patientsSection(state)),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _headerRow(AppointmentsState state) {
    final today = _now;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_weekdays[today.weekday - 1]}, '
          '${today.day}${_ordinalSuffix(today.day)} ${_months[today.month - 1]}',
          style: const TextStyle(fontSize: 17, color: muted),
        ),
        const SizedBox(height: 6),
        StoreConnector<AppState, String?>(
          // The full profile's name once it has loaded; the login summary's
          // until then.
          converter: (store) =>
              store.state.authState.doctor?.fullName ??
              store.state.authState.userName,
          builder: (context, name) {
            return Text(
              '${timeOfDayGreeting(today)} ${greetingName(name)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.2,
              ),
            );
          },
        ),
      ],
    );

    final waiting = awaitingAcceptance(state.appointments, today);
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (waiting > 0) _alertBar(waiting) else const SizedBox(height: 26),
        const SizedBox(height: 4),
        StoreConnector<AppState, VoidCallback>(
          converter: (store) => () => _refresh(store),
          builder: (context, refresh) => IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: state.isLoading ? null : refresh,
            icon: const Icon(Icons.refresh_rounded,
                size: 26, color: Colors.black),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: title), actions],
        );
      },
    );
  }

  /// Bookings waiting on the doctor, the one thing on this page that asks
  /// them to act. Opens the Appointments page, where accepting happens.
  Widget _alertBar(int waiting) {
    return Material(
      color: const Color(0xFFF2EE7A),
      child: InkWell(
        onTap: () => context.go(AppRoutes.doctorAppointments),
        child: Container(
          height: 26,
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, size: 18, color: orange),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.tight,
                child: Text(
                  waiting == 1
                      ? '1 booking is waiting for you to accept'
                      : '$waiting bookings are waiting for you to accept',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF8A7A00)),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFF8A7A00)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Widget _statsRow(AppointmentsState state) {
    final now = _now;
    final ready = state.hasLoadedOnce;
    final thisMonth = appointmentsInMonth(state.appointments, now);
    final change = changeVersusLastMonth(state.appointments, now);
    final patients = patientsFromAppointments(state.appointments, now: now);
    final newThisMonth = newPatientsThisMonth(state.appointments, now);

    return _tealCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowWidth =
              constraints.maxWidth < 520 ? 520.0 : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: rowWidth,
              height: constraints.maxHeight,
              child: Row(
                children: [
                  _statTile(
                    Icons.calendar_month,
                    'Appointments this month',
                    ready ? '$thisMonth' : '—',
                    trend: change,
                    subtext: change == null ? '' : 'vs last month',
                    onTap: () => context.go(AppRoutes.doctorAppointments),
                  ),
                  _statDivider(),
                  _statTile(
                    Icons.person,
                    'Patients',
                    ready ? '${patients.length}' : '—',
                    trend: newThisMonth > 0 ? '+$newThisMonth' : null,
                    subtext: newThisMonth > 0 ? 'new this month' : '',
                    onTap: () => context.go(AppRoutes.doctorPatients),
                  ),
                  _statDivider(),
                  StoreConnector<AppState, ReviewsState>(
                    converter: (store) => store.state.reviewsState,
                    builder: (context, reviews) {
                      final summary = reviews.summary;
                      // Until the first fetch resolves there is nothing
                      // honest to show, and 0 would read as a bad score
                      // rather than an absent one.
                      final String subtext;
                      if (summary != null) {
                        subtext = summary.hasReviews
                            ? '${summary.averageLabel} out of 5'
                            : 'No reviews yet';
                      } else if (reviews.isLoading) {
                        subtext = 'Loading ratings...';
                      } else if (reviews.errorMessage != null) {
                        subtext = 'Ratings unavailable';
                      } else {
                        subtext = '';
                      }

                      return _statTile(
                        Icons.rate_review,
                        'Reviews',
                        summary == null ? '—' : '${summary.totalReviews}',
                        stars: summary == null
                            ? null
                            : _stars(summary.filledStars),
                        subtext: subtext,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The tile already drew stars as text; this keeps that and makes them
  /// reflect the real score.
  static String _stars(int filled) => ('★' * filled) + ('☆' * (5 - filled));

  /// One figure: icon, label, value, then either a trend chip ("+12%" with a
  /// note) or, for reviews, the stars with a note under them.
  Widget _statTile(
    IconData icon,
    String label,
    String value, {
    String? trend,
    String? stars,
    String subtext = '',
    VoidCallback? onTap,
  }) {
    final falling = trend?.startsWith('-') ?? false;
    final trendColor =
        falling ? const Color(0xFFE0533D) : const Color(0xFF24C35B);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: mint,
                child: Icon(icon, size: 19, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (stars != null) ...[
                Text(stars,
                    style: const TextStyle(fontSize: 11, color: Colors.black)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    subtext,
                    style:
                        const TextStyle(fontSize: 8, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ] else if (stars == null && trend == null && subtext.isNotEmpty)
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF8A8A8A)),
                )
              else if (trend != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            falling ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 10,
                            color: trendColor,
                          ),
                          const SizedBox(width: 2),
                          Text(trend,
                              style: TextStyle(fontSize: 9, color: trendColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtext,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF9A9A9A)),
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

  Widget _statDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 20),
      color: const Color(0xFFCFCFCF),
    );
  }

  // ─── Today's appointments ──────────────────────────────────────────────────

  Widget _appointmentsSection(AppointmentsState state) {
    final now = _now;
    final today = todaysAppointments(state.appointments, now);

    final Widget body;
    if (!state.hasLoadedOnce && state.isLoading) {
      body = const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: aqua),
        ),
      );
    } else if (state.errorMessage != null && state.appointments.isEmpty) {
      body = _sectionNote(
          'Could not load your appointments.\n${state.errorMessage}');
    } else if (today.isEmpty) {
      final next = nextAppointmentAfterToday(state.appointments, now);
      body = _sectionNote(
        next == null
            ? 'No appointments today.'
            : 'No appointments today.\n\nNext: ${next.patientName}, '
                '${next.formattedDate} at ${next.timeSlot ?? '—'}',
      );
    } else {
      body = _timeline(today);
    }

    return _tealCard(
      padding: const EdgeInsets.fromLTRB(14, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Appointments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${_months[now.month - 1].substring(0, 3)} '
                '${now.day}${_ordinalSuffix(now.day)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _sectionNote(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: muted),
      ),
    );
  }

  /// The hours the day's timeline spans: at least 08:00–15:00, widened to
  /// take in any appointment outside that.
  (int, int) _hourRange(List<Appointment> today) {
    var start = 8;
    var end = 15;
    for (final a in today) {
      final minutes = startMinutes(a);
      if (minutes ~/ 60 < start) start = minutes ~/ 60;
      if (minutes ~/ 60 + 1 > end) end = minutes ~/ 60 + 1;
    }
    return (start, end.clamp(start + 1, 24));
  }

  /// The day as the design draws it: hour labels on a vertical line that
  /// breaks around them, each appointment card at its start time, and a short
  /// connector from a dot on the card's teal edge across to the card. The
  /// appointment in progress, or the next one, is the lavender card.
  Widget _timeline(List<Appointment> today) {
    final (startHour, endHour) = _hourRange(today);
    final current = currentOrNextIndex(today, _now);

    // Measured from the inside of the card's padding.
    const labelWidth = 31.0;
    const lineX = 15.0;
    const cardLeft = 41.0;
    const cardHeight = 52.0;
    const connectorY = 16.0;
    // The dot sits on the card's teal edge, outside this padding.
    const dotX = -16.0;
    const lineColor = Color(0xFF8FB9BD);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final hours = endHour - startHour;
        final hourHeight = (height - 12) / hours;
        final minuteHeight = hourHeight / 60;
        double topFor(Appointment a) =>
            ((startMinutes(a) - startHour * 60) * minuteHeight)
                .clamp(0.0, math.max(0.0, height - cardHeight))
                .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 6,
              bottom: 0,
              left: lineX - 0.75,
              child: Container(width: 1.5, color: lineColor),
            ),
            // On a white ground, so the line breaks around each label.
            for (var h = 0; h <= hours; h++)
              Positioned(
                top: h * hourHeight,
                left: 0,
                width: labelWidth,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${(startHour + h).toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: faint),
                  ),
                ),
              ),
            for (var i = 0; i < today.length; i++) ...[
              Positioned(
                top: topFor(today[i]) + connectorY - 0.75,
                left: dotX,
                width: cardLeft - dotX,
                height: 1.5,
                child: const ColoredBox(color: lineColor),
              ),
              Positioned(
                top: topFor(today[i]) + connectorY - 3,
                left: dotX - 3,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: darkTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: topFor(today[i]),
                left: cardLeft,
                right: 0,
                height: cardHeight,
                child: _appointmentCard(today[i], highlight: i == current),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Name and time, as in the design. The status is in the tooltip and the
  /// details sheet; a document mark shows when the patient gave a reason.
  Widget _appointmentCard(Appointment appt, {required bool highlight}) {
    final reason = appt.reason?.trim() ?? '';
    final radius = BorderRadius.circular(10);

    // The card sits on a rounded teal shape that shows down its left side,
    // so the stripe follows the card's curved corners, as the big cards' edge
    // does.
    return Tooltip(
      message: appt.statusLabel,
      child: Container(
        decoration: BoxDecoration(color: _stripe, borderRadius: radius),
        padding: const EdgeInsets.only(left: _stripeWidth),
        child: Material(
          color: highlight ? lavender : mint,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showAppointmentDetails(appt),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          appt.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appt.timeRange,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A8B8E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reason.isNotEmpty)
                    Tooltip(
                      message: reason,
                      child: const Icon(
                        Icons.description,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The appointment cards' left stripe.
  static const Color _stripe = Color(0xFF48BFC4);
  static const double _stripeWidth = 4;

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final reason = appointment.reason?.trim() ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.patientName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('${appointment.formattedDate}, ${appointment.timeRange}'),
              const SizedBox(height: 4),
              Text('Status: ${appointment.statusLabel}'),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Reason: $reason'),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go(AppRoutes.doctorAppointments);
                    },
                    child: const Text('Open in Appointments'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Activity trend ────────────────────────────────────────────────────────

  Widget _activitySection(AppointmentsState state) {
    final buckets = activityTrend(state.appointments, selectedTrend, _now);
    final peak =
        buckets.fold<int>(0, (m, b) => b.appointments > m ? b.appointments : m);
    // A round top for the axis, so its labels are whole numbers.
    final top = peak <= 4 ? 4 : ((peak + 3) ~/ 4) * 4;

    return _tealCard(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activity Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _trendChip('Daily', TrendPeriod.weekly),
                    _trendChip('Monthly', TrendPeriod.monthly),
                    _trendChip('Yearly', TrendPeriod.yearly),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Padding(
                    // Lines up with the bars, above the month labels.
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 4; i >= 0; i--)
                          Text(
                            '${top * i ~/ 4}',
                            style: const TextStyle(
                                fontSize: 11, color: faint, height: 1),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18, top: 5),
                        child: Column(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFE8EFF0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final bucket in buckets)
                            Expanded(child: _trendBar(bucket, top)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Legend(color: darkTeal, label: 'Patients'),
              SizedBox(width: 46),
              _Legend(color: mint, label: 'Appointments'),
            ],
          ),
        ],
      ),
    );
  }

  /// Appointments as the light bar, the distinct patients among them as the
  /// dark bar in front.
  Widget _trendBar(TrendBucket bucket, int top) {
    return Tooltip(
      message: '${bucket.label}: ${bucket.appointments} appointments, '
          '${bucket.patients} patients',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = math.min(38.0, constraints.maxWidth * 0.72);
          Widget bar(double factor, Color color) => FractionallySizedBox(
                heightFactor: factor,
                child: Container(
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              );

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      bar(bucket.appointments / top, mint),
                      bar(bucket.patients / top, darkTeal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 12,
                child: Text(
                  bucket.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: faint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _trendChip(String text, TrendPeriod period) {
    final selected = selectedTrend == period;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => selectedTrend = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? darkTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: selected ? Colors.white : const Color(0xFF9BB5B8),
          ),
        ),
      ),
    );
  }

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // ─── Recent patients ───────────────────────────────────────────────────────

  Widget _patientsSection(AppointmentsState state) {
    final now = _now;
    final all = patientsFromAppointments(state.appointments, now: now);
    // The top bar's search, when this page is inside the doctor's shell.
    final query = DoctorSearchScope.maybeOf(context)?.value.trim() ?? '';
    final visible = all
        .where((p) =>
            patientFilter.keeps(patientStatus(state.appointments, p.id, now)))
        .where((p) => patientMatches(p, query))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 844 ? 780.0 : constraints.maxWidth - 64;

        return Container(
          padding: const EdgeInsets.fromLTRB(30, 16, 34, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: mint,
                        child:
                            Icon(Icons.person, size: 24, color: Colors.black),
                      ),
                      const SizedBox(width: 18),
                      const Text(
                        'Patients',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(width: 32),
                      // Scrolls sideways if the card is too narrow for all
                      // five, rather than overflow.
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: PatientFilterChips(
                            selected: patientFilter,
                            onSelected: (filter) =>
                                setState(() => patientFilter = filter),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.doctorPatients),
                        child: const Text(
                          'View all',
                          style: TextStyle(fontSize: 15, color: darkTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _patientHeader(tableWidth),
              Container(
                width: tableWidth,
                height: 2,
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                color: const Color(0xFFF0F2F2),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          !state.hasLoadedOnce
                              ? ''
                              : all.isEmpty
                                  ? 'Patients appear here once they book with you'
                                  : query.isNotEmpty
                                      ? 'No patients match "$query"'
                                      : 'No patients under ${patientFilter.label}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : PatientTableList(
                        // The rows have no padding of their own here, so
                        // this keeps them clear of the scrollbar.
                        padding: const EdgeInsets.only(right: 18),
                        itemCount: visible.length,
                        itemBuilder: (context, index) => _patientRow(
                          visible[index],
                          state.appointments,
                          now,
                          tableWidth,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The Patients page's own column labels, so the two tables match.
  Widget _patientHeader(double tableWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: tableWidth, child: const PatientTableHeader()),
    );
  }

  /// The Patients page's own row: the same cells, and a click on it or its
  /// three dots opens the patient's actions rather than the profile.
  Widget _patientRow(
    DoctorPatient patient,
    List<Appointment> appointments,
    DateTime now,
    double tableWidth,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: PatientTableRow(
          patient: patient,
          status: patientStatus(appointments, patient.id, now),
          lastVisit: lastVisit(appointments, patient.id, now),
          now: now,
          onOpenProfile: () =>
              context.push('${AppRoutes.doctorPatients}/${patient.id}'),
        ),
      ),
    );
  }

  /// A white card with the design's curved teal edge down its left side.
  Widget _tealCard({
    required Widget child,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: aqua,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 10, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9AA7A9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

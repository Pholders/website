import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/utils/greeting.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../../appointments/redux/appointments_state.dart';
import '../../patients/data/doctor_patient.dart';
import '../../reviews/redux/reviews_actions.dart';
import '../../reviews/redux/reviews_state.dart';
import '../data/dashboard_summary.dart';

/// The doctor's home: today's appointments, what is waiting on them, how busy
/// they have been, and the patients they saw most recently.
///
/// All of it is worked out from the doctor's own appointments, the list the
/// Appointments and Patients pages load. It used to be invented: four
/// "Maria Wilson" appointments on 14 March, a "72 appointments, +12%" tile,
/// a medication alert about a made-up patient, a fixed chart, and a patient
/// table with conditions, statuses and priorities nobody recorded, whose add,
/// edit and delete changed only the screen.
class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key, this.clock});

  /// Stands in for the time of day in tests.
  final DateTime Function()? clock;

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  TrendPeriod selectedTrend = TrendPeriod.monthly;
  bool upcomingOnly = false;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  static const Color primaryTeal = Color(0xFF48BFC4);
  static const Color darkTeal = Color(0xFF2E9FA5);
  static const Color lightTealBg = Color(0xFFE4F8F9);
  static const Color cardMint = Color(0xFFE2F6F7);
  static const Color orange = Color(0xFFFFA51E);
  static const Color lavender = Color(0xFFEDE3FF);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
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
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 720.0;

          final compact = width < 860;
          final contentHeight = height < 620 ? 620.0 : height;
          final dashboardHeight = contentHeight - 48;
          final shouldScroll = compact || height < 700;

          final dashboardPanel = Container(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
            decoration: BoxDecoration(
              color: lightTealBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: compact
                ? _compactLayout(state)
                : SizedBox(
                    height: dashboardHeight,
                    child: _desktopLayout(state),
                  ),
          );

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: shouldScroll
                ? SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: contentHeight - 8),
                      child: dashboardPanel,
                    ),
                  )
                : SizedBox(
                    height: contentHeight - 8,
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
        _headerRow(state),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 255, child: _appointmentsSection(state)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 124, child: _statsRow(state)),
                    const SizedBox(height: 14),
                    Expanded(child: _activitySection(state)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(flex: 2, child: _patientsSection(state)),
      ],
    );
  }

  Widget _compactLayout(AppointmentsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(state),
        const SizedBox(height: 12),
        SizedBox(height: 280, child: _appointmentsSection(state)),
        const SizedBox(height: 14),
        SizedBox(height: 124, child: _statsRow(state)),
        const SizedBox(height: 14),
        SizedBox(height: 210, child: _activitySection(state)),
        const SizedBox(height: 14),
        SizedBox(height: 240, child: _patientsSection(state)),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF7C8B8D)),
        ),
        const SizedBox(height: 5),
        StoreConnector<AppState, String?>(
          converter: (store) => store.state.authState.userName,
          builder: (context, userName) {
            final name = userName?.trim() ?? '';
            return Text(
              '${timeOfDayGreeting(today)} ${name.isEmpty ? 'Doctor' : name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Color(0xFF102025),
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
        if (waiting > 0) _alertPill(waiting),
        const SizedBox(height: 10),
        StoreConnector<AppState, VoidCallback>(
          converter: (store) => () => _refresh(store),
          builder: (context, refresh) => IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: state.isLoading ? null : refresh,
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.black),
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
  Widget _alertPill(int waiting) {
    return InkWell(
      onTap: () => context.go(AppRoutes.doctorAppointments),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: const Color(0xFFFFE760),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: orange),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                waiting == 1
                    ? '1 booking is waiting for you to accept'
                    : '$waiting bookings are waiting for you to accept',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7A6800)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFF7A6800)),
          ],
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
              child: Row(
                children: [
                  _statTile(
                    Icons.calendar_month,
                    'Appointments this month',
                    ready ? '$thisMonth' : '—',
                    change ?? '',
                    change == null ? '' : 'vs last month',
                    onTap: () => context.go(AppRoutes.doctorAppointments),
                  ),
                  _statDivider(),
                  _statTile(
                    Icons.person,
                    'Patients',
                    ready ? '${patients.length}' : '—',
                    newThisMonth > 0 ? '+$newThisMonth' : '',
                    newThisMonth > 0 ? 'new this month' : '',
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
                        Icons.reviews,
                        'Reviews',
                        summary == null ? '—' : '${summary.totalReviews}',
                        summary == null ? '' : _stars(summary.filledStars),
                        subtext,
                        isReview: true,
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

  Widget _statTile(
    IconData icon,
    String label,
    String value,
    String meta,
    String subtext, {
    VoidCallback? onTap,
    bool isReview = false,
  }) {
    final falling = meta.startsWith('-');
    final trendColor =
        falling ? const Color(0xFFE0533D) : const Color(0xFF24C35B);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: cardMint,
                child: Icon(icon, size: 13, color: Colors.black),
              ),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black)),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              if (isReview) ...[
                Text(meta, style: const TextStyle(fontSize: 10, color: Colors.black)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    subtext,
                    style: const TextStyle(fontSize: 8, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ] else if (meta.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      falling ? Icons.trending_down : Icons.trending_up,
                      size: 8,
                      color: trendColor,
                    ),
                    const SizedBox(width: 3),
                    Text(meta, style: TextStyle(fontSize: 9, color: trendColor)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtext,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF9A9A9A)),
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
      margin: const EdgeInsets.symmetric(vertical: 16),
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
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal),
        ),
      );
    } else if (state.errorMessage != null && state.appointments.isEmpty) {
      body = _sectionNote('Could not load your appointments.\n${state.errorMessage}');
    } else if (today.isEmpty) {
      final next = nextAppointmentAfterToday(state.appointments, now);
      body = _sectionNote(
        next == null
            ? 'No appointments today.'
            : 'No appointments today.\n\nNext: ${next.patientName}, '
                '${next.formattedDate} at ${next.timeSlot ?? '—'}',
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _timelineAxis(today),
          const SizedBox(width: 8),
          Expanded(child: _appointmentTimeline(today)),
        ],
      );
    }

    return _tealCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's appointments",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_months[now.month - 1].substring(0, 3)} '
                '${now.day}${_ordinalSuffix(now.day)}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        style: const TextStyle(fontSize: 11, color: Color(0xFF7C8B8D)),
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

  Widget _appointmentTimeline(List<Appointment> today) {
    final (startHour, endHour) = _hourRange(today);
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardHeight = 38.0;
        final timelineHeight = constraints.maxHeight;
        final minuteHeight = timelineHeight / ((endHour - startHour) * 60);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < today.length; i++)
              Positioned(
                top: ((startMinutes(today[i]) - startHour * 60) * minuteHeight)
                    .clamp(0.0, (timelineHeight - cardHeight).clamp(0.0, double.infinity))
                    .toDouble(),
                left: 0,
                right: 0,
                height: cardHeight,
                child: _appointmentCard(today[i], highlight: i == 0),
              ),
          ],
        );
      },
    );
  }

  Widget _timelineAxis(List<Appointment> today) {
    final (startHour, endHour) = _hourRange(today);
    return SizedBox(
      width: 34,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var h = startHour; h <= endHour; h++)
                  Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontSize: 8, color: Color(0xFF8C9A9D)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(width: 1, color: const Color(0xFFC6D4D6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentCard(Appointment appt, {required bool highlight}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showAppointmentDetails(appt),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 6, 9, 6),
        decoration: BoxDecoration(
          color: highlight ? lavender : cardMint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${appt.timeRange}  ·  ${appt.statusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF7A8B8E)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    final peak = buckets.fold<int>(0, (m, b) => b.appointments > m ? b.appointments : m);
    // A round top for the axis, so its labels are whole numbers.
    final top = peak <= 4 ? 4 : ((peak + 3) ~/ 4) * 4;

    return _tealCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activity Trend',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              _trendChip('Week', TrendPeriod.weekly),
              _trendChip('Monthly', TrendPeriod.monthly),
              _trendChip('Yearly', TrendPeriod.yearly),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 4; i >= 0; i--)
                        Text(
                          '${top * i ~/ 4}',
                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          for (var i = 0; i < 4; i++)
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(height: 1, color: const Color(0xFFE8EFF0)),
                              ),
                            ),
                        ],
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
          const SizedBox(height: 6),
          const Row(
            children: [
              _Legend(color: darkTeal, label: 'Patients'),
              SizedBox(width: 28),
              _Legend(color: cardMint, label: 'Appointments'),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: bucket.appointments / top,
                      child: Container(
                        width: 26,
                        decoration: BoxDecoration(
                          color: cardMint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      heightFactor: bucket.patients / top,
                      child: Container(
                        width: 26,
                        decoration: BoxDecoration(
                          color: darkTeal,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              bucket.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendChip(String text, TrendPeriod period) {
    final selected = selectedTrend == period;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => selectedTrend = period),
      child: Container(
        margin: const EdgeInsets.only(left: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? darkTeal : cardMint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: selected ? Colors.white : const Color(0xFF8CA2A5),
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
    final visible = upcomingOnly
        ? all.where((p) => p.nextVisit != null).toList()
        : all;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 824 ? 780.0 : constraints.maxWidth - 44;

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
                        radius: 12,
                        backgroundColor: cardMint,
                        child: Icon(Icons.person, size: 15, color: Colors.black),
                      ),
                      const SizedBox(width: 13),
                      const Text(
                        'Recent patients',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 28),
                      _filterChip('All', !upcomingOnly, () => setState(() => upcomingOnly = false)),
                      _filterChip('With an upcoming visit', upcomingOnly, () => setState(() => upcomingOnly = true)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.doctorPatients),
                        child: const Text('View all', style: TextStyle(color: darkTeal)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _patientHeader(tableWidth),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          !state.hasLoadedOnce
                              ? ''
                              : all.isEmpty
                                  ? 'Patients appear here once they book with you'
                                  : 'No patients with an upcoming visit',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _patientRow(
                          visible[index],
                          lastVisit(state.appointments, visible[index].id, now),
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

  Widget _filterChip(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: selected ? Colors.white : const Color(0xFF8C8C8C),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _patientHeader(double tableWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: const Row(
          children: [
            Expanded(flex: 3, child: _HeaderText('Name')),
            Expanded(flex: 3, child: _HeaderText('Last reason for visit')),
            Expanded(flex: 2, child: _HeaderText('Last visit')),
            Expanded(flex: 2, child: _HeaderText('Next visit')),
            Expanded(flex: 1, child: _HeaderText('Visits')),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    return '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';
  }

  Widget _patientRow(DoctorPatient patient, DateTime? last, double tableWidth) {
    const cell = TextStyle(fontSize: 9, color: Color(0xFF777777));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('${AppRoutes.doctorPatients}/${patient.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _patientAvatar(patient),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(patient.name, overflow: TextOverflow.ellipsis, style: cell),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(patient.lastReason ?? '—', overflow: TextOverflow.ellipsis, style: cell),
                ),
                Expanded(flex: 2, child: Text(_shortDate(last), style: cell)),
                Expanded(flex: 2, child: Text(_shortDate(patient.nextVisit), style: cell)),
                Expanded(flex: 1, child: Text('${patient.visits}', style: cell)),
                const SizedBox(
                  width: 24,
                  child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF6C6C6C)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _patientAvatar(DoctorPatient patient) {
    final url = patient.avatarUrl;
    return CircleAvatar(
      radius: 12,
      backgroundColor: primaryTeal,
      foregroundImage: url == null ? null : NetworkImage(url),
      onForegroundImageError: url == null ? null : (_, __) {},
      child: Text(
        patient.initials,
        style: const TextStyle(fontSize: 8, color: Colors.white),
      ),
    );
  }

  Widget _tealCard({
    required Widget child,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: primaryTeal, width: 6)),
      ),
      child: Padding(padding: padding, child: child),
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
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 9, color: Color(0xFF8A8A8A)),
    );
  }
}

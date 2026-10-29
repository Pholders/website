import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../shared/theme/app_theme.dart';
import '../data/models/appointment.dart';
import '../redux/appointments_actions.dart';

/// Doctor Appointments page matching Figma "List of appointments".
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int _selectedTab = 0;

  /// Opens on the month: on a single day, Past visits is usually empty.
  String _viewMode = 'Month';

  /// The day the period is built around; the arrows and the date chip move it.
  DateTime _anchor = DateUtils.dateOnly(DateTime.now());

  DateTimeRange get _period => periodFor(_viewMode, _anchor);

  void _step(int direction) =>
      setState(() => _anchor = stepAnchor(_viewMode, _anchor, direction));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _anchor = DateUtils.dateOnly(picked));
    }
  }

  @override
  void initState() {
    super.initState();
    // Dispatch after the first frame so the store is available via context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context)
            .dispatch(const LoadAppointmentsAction());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF6DD0D8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Title ──────────────────────────────────────────────────────
              const Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stay organized and on track with calender',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ── Tab bar ────────────────────────────────────────────────────
              StoreConnector<AppState, List<Appointment>>(
                distinct: true,
                converter: (store) => store.state.appointmentsState.appointments,
                builder: (context, all) {
                  // Counted in the builder, not the converter, so a change of
                  // period (a setState here) is reflected straight away.
                  final now = DateTime.now();
                  final shown = all.where((a) => a.isWithin(_period)).toList();
                  final past = shown.where((a) => a.isPastAt(now)).length;
                  return _TabBar(
                    labels: [
                      'Future visits (${shown.length - past})',
                      'Past visits ($past)',
                      'Planned Treatments',
                    ],
                    selectedIndex: _selectedTab,
                    onTabChanged: (i) => setState(() => _selectedTab = i),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Calendar content ───────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      _CalendarHeader(
                        viewMode: _viewMode,
                        label: periodLabel(_viewMode, _anchor),
                        chipLabel: _shortDate(_anchor),
                        onPrevious: () => _step(-1),
                        onNext: () => _step(1),
                        onPickDate: _pickDate,
                        onViewModeChanged: (v) =>
                            setState(() => _viewMode = v),
                      ),
                      const Divider(height: 1, color: AppTheme.divider),
                      Expanded(
                        child: StoreConnector<AppState, _AppointmentsViewModel>(
                          converter: _AppointmentsViewModel.fromStore,
                          builder: (context, vm) => _AppointmentsBody(
                            vm: vm,
                            tab: _selectedTab,
                            period: _period,
                            periodName: _periodName(_viewMode),
                            onRetry: () => StoreProvider.of<AppState>(context)
                                .dispatch(const LoadAppointmentsAction()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Period (Day / Week / Month) ───────────────────────────────────────────────

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// The day, the week (Monday to Sunday) or the month around [anchor], as a
/// start-inclusive, end-exclusive range.
DateTimeRange periodFor(String viewMode, DateTime anchor) {
  final day = DateUtils.dateOnly(anchor);
  switch (viewMode) {
    case 'Week':
      final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
      return DateTimeRange(start: start, end: DateUtils.addDaysToDate(start, 7));
    case 'Month':
      return DateTimeRange(
          start: DateTime(day.year, day.month),
          end: DateTime(day.year, day.month + 1));
    default:
      return DateTimeRange(start: day, end: DateUtils.addDaysToDate(day, 1));
  }
}

/// Moves [anchor] one day, week or month in [direction] (-1 or 1).
///
/// A month step keeps the day of the month (clamped: 31 Jan → 28/29 Feb), so
/// stepping away and back returns to the same day rather than the 1st.
DateTime stepAnchor(String viewMode, DateTime anchor, int direction) {
  switch (viewMode) {
    case 'Week':
      return DateUtils.addDaysToDate(anchor, 7 * direction);
    case 'Month':
      final first = DateTime(anchor.year, anchor.month + direction);
      final last = DateUtils.getDaysInMonth(first.year, first.month);
      return DateTime(first.year, first.month,
          anchor.day < last ? anchor.day : last);
    default:
      return DateUtils.addDaysToDate(anchor, direction);
  }
}

/// "29 October 2026", "26 Oct – 1 Nov 2026" or "October 2026".
String periodLabel(String viewMode, DateTime anchor) {
  final range = periodFor(viewMode, anchor);
  final start = range.start;
  switch (viewMode) {
    case 'Week':
      final last = DateUtils.addDaysToDate(range.end, -1);
      return '${_shortDate(start)} – ${_shortDate(last)} ${last.year}';
    case 'Month':
      return '${_monthNames[start.month - 1]} ${start.year}';
    default:
      return '${start.day} ${_monthNames[start.month - 1]} ${start.year}';
  }
}

String _shortDate(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1].substring(0, 3)}';

String _periodName(String viewMode) => viewMode.toLowerCase();

extension on Appointment {
  /// Whether the visit's day falls inside [range]. A visit with no date is in
  /// no period.
  bool isWithin(DateTimeRange range) {
    final d = date?.toLocal();
    if (d == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(range.start) && day.isBefore(range.end);
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {

  const _TabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onTabChanged,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = labels;
    const activeColor = Color(0xFF309CA3);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTabChanged(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? activeColor : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    height: 5,
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Calendar header ──────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {

  const _CalendarHeader({
    required this.viewMode,
    required this.label,
    required this.chipLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
    required this.onViewModeChanged,
  });
  final String viewMode;

  /// The period on screen: "29 October 2026", "26 Oct – 1 Nov 2026" or
  /// "October 2026". It used to be a fixed "15 April 2026".
  final String label;
  final String chipLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final ValueChanged<String> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous ${viewMode.toLowerCase()}',
            visualDensity: VisualDensity.compact,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left,
                size: 22, color: AppTheme.textSecondary),
          ),
          IconButton(
            tooltip: 'Next ${viewMode.toLowerCase()}',
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right,
                size: 22, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _ViewToggle(selected: viewMode, onChanged: onViewModeChanged),
          const SizedBox(width: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Image.asset('assets/calender.png',
                      width: 14, height: 14),
                  const SizedBox(width: 6),
                  Text(
                    chipLabel,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {

  const _ViewToggle({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['Day', 'Week', 'Month'];
    const activeColor = Color(0xFF309CA3);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Time grid ────────────────────────────────────────────────────────────────

class _TimeGrid extends StatelessWidget {

  const _TimeGrid({required this.appointments});
  final List<Appointment> appointments;

  /// Rows to draw: every hour that has a booking, widened to the 9am-12pm
  /// window from the design so the grid never collapses to a single row.
  List<int> get _hours {
    final booked = appointments.map((a) => a.hour).toSet();
    final start = [9, ...booked].reduce((a, b) => a < b ? a : b);
    final end = [12, ...booked].reduce((a, b) => a > b ? a : b);
    return [for (var h = start; h <= end; h++) h];
  }

  static String _hourLabel(int hour) {
    if (hour == 0) return '12 am';
    if (hour == 12) return '12 pm';
    return hour < 12 ? '$hour am' : '${hour - 12} pm';
  }

  @override
  Widget build(BuildContext context) {
    final hours = _hours;

    return Column(
      children: List.generate(hours.length, (i) {
        final hour = hours[i];
        final label = _hourLabel(hour);
        final appts = appointments.where((a) => a.hour == hour).toList();

        return Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.divider),
              // Appointment cards
              Expanded(
                child: appts.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: appts
                              .map((a) => _AppointmentCard(data: a))
                              .toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Appointment card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {

  const _AppointmentCard({required this.data});
  final Appointment data;

  /// Opens the actions for this consultation.
  ///
  /// Deliberately a tap on the existing card rather than buttons added to it:
  /// the card layout is unchanged, it just does something now.
  void _openActions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AppointmentActionsDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    const tealLight = Color(0xFFE0F5F5);
    const tealBorder = Color(0xFF309CA3);

    const bgColor = tealLight;
    const leftBorder = tealBorder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: GestureDetector(
        onTap: () => _openActions(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: leftBorder, width: 3),
          ),
        ),
      child: Row(
        children: [
          // Time + Date
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.timeRange,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Service
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(data.reason ?? 'Consultation',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Patient
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(data.patientName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              _StatusBadge(status: data.statusLabel),
            ],
          ),

        

          // Action icon
          Image.asset(
            'assets/arrow-actions-icon.png',
            width: 18,
            height: 18,
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6DD0D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
         
        ],
      ),
    );
  }
}

// ─── Store bindings ───────────────────────────────────────────────────────────

class _AppointmentsViewModel {
  const _AppointmentsViewModel({
    required this.appointments,
    required this.isLoading,
    required this.hasLoadedOnce,
    this.errorMessage,
  });

  factory _AppointmentsViewModel.fromStore(Store<AppState> store) {
    final state = store.state.appointmentsState;
    return _AppointmentsViewModel(
      appointments: state.appointments,
      isLoading: state.isLoading,
      hasLoadedOnce: state.hasLoadedOnce,
      errorMessage: state.errorMessage,
    );
  }

  final List<Appointment> appointments;
  final bool isLoading;
  final bool hasLoadedOnce;
  final String? errorMessage;
}

/// Switches between the loading, error, empty and populated states of the
/// calendar area.
class _AppointmentsBody extends StatelessWidget {
  const _AppointmentsBody({
    required this.vm,
    required this.tab,
    required this.period,
    required this.periodName,
    required this.onRetry,
  });

  /// Only visits inside this day, week or month are shown.
  final DateTimeRange period;

  /// "day", "week" or "month", for the empty-state wording.
  final String periodName;

  final _AppointmentsViewModel vm;

  /// 0 future visits, 1 past visits, 2 planned treatments.
  final int tab;
  final VoidCallback onRetry;

  /// The selected tab's visits. The tabs used to only change colour, so all
  /// three showed the same list.
  List<Appointment> _visits() {
    final now = DateTime.now();
    final past = tab == 1;
    final list = vm.appointments
        .where((a) => a.isWithin(period) && a.isPastAt(now) == past)
        .toList();
    final far = DateTime(9999);
    int byTime(Appointment a, Appointment b) {
      final c = (a.date ?? far).compareTo(b.date ?? far);
      return c != 0 ? c : (a.timeSlot ?? '').compareTo(b.timeSlot ?? '');
    }
    // Soonest first ahead; most recent first behind.
    list.sort(past ? (a, b) => byTime(b, a) : byTime);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Only block the whole area on the very first load; later refreshes keep
    // the existing appointments on screen.
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF309CA3)),
              SizedBox(height: 16),
              // The API sleeps on Render's free tier, so the first request
              // after a while genuinely can take half a minute.
              Text(
                'Loading appointments…',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.errorMessage != null && vm.appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 40, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (tab == 2) {
      return const _TabNotice(
        icon: Icons.medical_services_outlined,
        title: 'No planned treatments yet',
        detail: 'Treatment plans are not stored by the platform yet, so there '
            'is nothing to list here.',
      );
    }

    final visits = _visits();
    if (vm.appointments.isNotEmpty && visits.isEmpty) {
      return tab == 1
          ? _TabNotice(
              icon: Icons.history_rounded,
              title: 'No past visits this $periodName',
              detail: 'Completed consultations and appointments whose day has '
                  'passed appear here. Use the arrows to look further back.',
            )
          : _TabNotice(
              icon: Icons.event_available_outlined,
              title: 'No upcoming visits this $periodName',
              detail: 'Use the arrows or switch to Week or Month to look '
                  'further ahead.',
            );
    }

    if (vm.appointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined,
                  size: 40, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'No appointments waiting for you',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              // Worth spelling out: the endpoint only returns appointments the
              // doctor has not accepted yet, so an empty list is not the same
              // as an empty diary.
              Text(
                'Appointments appear here until you accept them.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: _TimeGrid(appointments: visits),
    );
  }
}

class _TabNotice extends StatelessWidget {
  const _TabNotice({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment actions ──────────────────────────────────────────────────────

/// What the doctor can do with a consultation, opened by tapping its card.
///
/// Only the two things the API supports are offered. Accepting acknowledges
/// the consultation; completing it finalises payment on the backend and can
/// trigger the prescription flow, so it confirms first and cannot be undone.
class _AppointmentActionsDialog extends StatelessWidget {
  const _AppointmentActionsDialog({required this.data});

  final Appointment data;

  Future<void> _complete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark this consultation complete?'),
        content: Text(
          'This finalises payment for ${data.patientName} and cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // The dialog stays open with a spinner until the server answers, then
    // closes and says how it went (see onDidChange below). Closing at once
    // hid a refusal completely.
    StoreProvider.of<AppState>(context)
        .dispatch(CompleteAppointmentAction(appointmentId: data.id));
  }

  /// Why "Mark complete" is not offered, or null when it is.
  String? get _cannotCompleteReason => switch (data.status) {
        'pending_payment' =>
          'Can be completed once the patient has paid for it.',
        'completed' => 'This consultation is completed.',
        'cancelled' => 'This appointment was cancelled.',
        _ => null,
      };

  void _accept(BuildContext context) {
    StoreProvider.of<AppState>(context)
        .dispatch(AcceptAppointmentAction(appointmentId: data.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ({bool busy, String? error})>(
      distinct: true,
      converter: (store) => (
        busy: store.state.appointmentsState.pendingActionIds.contains(data.id),
        error: store.state.appointmentsState.errorMessage,
      ),
      onDidChange: (previous, current) {
        // Only the complete call keeps this dialog open while it runs.
        if (previous?.busy != true || current.busy) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
          content: Text(current.error ??
              'Consultation with ${data.patientName} marked complete'),
          backgroundColor: current.error == null ? null : Colors.red.shade700,
        ));
      },
      builder: (context, vm) {
        final isBusy = vm.busy;
        final reason = _cannotCompleteReason;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(data.patientName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('When', '${data.formattedDate} ${data.timeRange}'),
              if (data.reason != null) _line('Reason', data.reason!),
              _line('Status', data.statusLabel),
              if (data.patientPhone != null) _line('Phone', data.patientPhone!),
              if (data.patientEmail != null) _line('Email', data.patientEmail!),
              if (reason != null) ...[
                const SizedBox(height: 6),
                Text(reason,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ],
          ),
          actions: isBusy
              ? const [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  // Already-accepted consultations do not come back from this
                  // endpoint, so this is always the un-accepted case.
                  if (!data.doctorAccepted &&
                      data.status != 'completed' &&
                      data.status != 'cancelled')
                    TextButton(
                      onPressed: () => _accept(context),
                      child: const Text('Accept'),
                    ),
                  if (data.canComplete)
                    FilledButton(
                      onPressed: () => _complete(context),
                      child: const Text('Mark complete'),
                    ),
                ],
        );
      },
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}

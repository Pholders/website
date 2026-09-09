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
  String _viewMode = 'Day';

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
              _TabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
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
                        onViewModeChanged: (v) =>
                            setState(() => _viewMode = v),
                      ),
                      const Divider(height: 1, color: AppTheme.divider),
                      Expanded(
                        child: StoreConnector<AppState, _AppointmentsViewModel>(
                          converter: _AppointmentsViewModel.fromStore,
                          builder: (context, vm) => _AppointmentsBody(
                            vm: vm,
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

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {

  const _TabBar({required this.selectedIndex, required this.onTabChanged});
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Future visits(20)', 'Past visits', 'Planned Treatments'];
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
    required this.onViewModeChanged,
  });
  final String viewMode;
  final ValueChanged<String> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          const Text(
            '15 April 2026',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _ViewToggle(selected: viewMode, onChanged: onViewModeChanged),
          const SizedBox(width: 12),
          Container(
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
                const Text(
                  '15 Apr',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    const tealLight = Color(0xFFE0F5F5);
    const tealBorder = Color(0xFF309CA3);

    const bgColor = tealLight;
    const leftBorder = tealBorder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
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
  const _AppointmentsBody({required this.vm, required this.onRetry});

  final _AppointmentsViewModel vm;
  final VoidCallback onRetry;

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
      child: _TimeGrid(appointments: vm.appointments),
    );
  }
}

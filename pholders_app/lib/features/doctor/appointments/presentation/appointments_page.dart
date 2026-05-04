import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';

/// Doctor Appointments page.
///
/// Matches Figma frame "List of appointments".
/// Shows a calendar-style day view with appointment slots,
/// tab filters (Future visits / Past visits / Planned Treatments),
/// and a Day/Week/Month toggle.
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int _selectedTab = 0; // 0=Future, 1=Past, 2=Planned
  String _viewMode = 'Day'; // Day | Week | Month
  final DateTime _selectedDate = DateTime(2026, 4, 15);

  // Sample appointment data matching Figma
  final List<_Appointment> _appointments = [
    _Appointment(
      patientName: 'Prince Mashumu',
      service: 'Treatment of diabetes',
      time: '11:00–12:00',
      date: '26 Apr 2026',
      status: 'Scheduled',
      hour: 11,
    ),
    _Appointment(
      patientName: 'Maria Wilson',
      service: 'Treatment of diabetes',
      time: '11:00–12:00',
      date: '26 Apr 2026',
      status: 'Scheduled',
      hour: 11,
    ),
    _Appointment(
      patientName: 'Maria Wilson',
      service: 'Treatment of diabetes',
      time: '11:00–12:00',
      date: '26 Apr 2026',
      status: 'Scheduled',
      hour: 12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────────────────
            _PageHeader(
              selectedDate: _selectedDate,
              viewMode: _viewMode,
              onViewModeChanged: (v) => setState(() => _viewMode = v),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Tab bar ──────────────────────────────────────────────────────
            _TabBar(
              selectedIndex: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Calendar view ────────────────────────────────────────────────
            Expanded(
              child: isMobile
                  ? _MobileAppointmentList(appointments: _appointments)
                  : _DayCalendarView(appointments: _appointments),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final DateTime selectedDate;
  final String viewMode;
  final ValueChanged<String> onViewModeChanged;

  const _PageHeader({
    required this.selectedDate,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointments',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Stay organized and on track with calendar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        // Date + view toggle
        Row(
          children: [
            // Date picker button
            _DateButton(date: selectedDate),
            const SizedBox(width: 12),
            // Day / Week / Month toggle
            _ViewToggle(
              selected: viewMode,
              onChanged: onViewModeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  const _DateButton({required this.date});

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.day} ${_monthName(date.month)} ${date.year}';
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

class _ViewToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ViewToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = ['Day', 'Week', 'Month'];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
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

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const _TabBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = ['Future visits (20)', 'Past visits', 'Planned Treatments'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onTabChanged(i),
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isSelected)
                  Container(
                    height: 2,
                    width: 80,
                    color: AppTheme.primary,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Day calendar view (desktop/tablet) ──────────────────────────────────────

class _DayCalendarView extends StatelessWidget {
  final List<_Appointment> appointments;

  const _DayCalendarView({required this.appointments});

  @override
  Widget build(BuildContext context) {
    const hours = [9, 10, 11, 12, 13, 14, 15];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 64,
            child: Column(
              children: [
                const SizedBox(height: 48), // header spacer
                ...hours.map((h) => _TimeSlot(hour: h)),
              ],
            ),
          ),

          const VerticalDivider(width: 1, color: AppTheme.divider),

          // Appointments column
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Column header
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppTheme.divider)),
                    ),
                    child: const Text(
                      '15 April 2026',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Hour rows
                  ...hours.map((h) {
                    final appts = appointments
                        .where((a) => a.hour == h)
                        .toList();
                    return _HourRow(hour: h, appointments: appts);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final int hour;
  const _TimeSlot({required this.hour});

  @override
  Widget build(BuildContext context) {
    final label = hour < 12 ? '${hour} am' : '${hour - 12} pm';
    return Container(
      height: 100,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  final int hour;
  final List<_Appointment> appointments;

  const _HourRow({required this.hour, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: appointments.isEmpty
          ? null
          : Column(
              children: appointments
                  .map((a) => _AppointmentCard(appointment: a))
                  .toList(),
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final _Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          // Dot
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${appointment.time} • ${appointment.service}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          _StatusBadge(status: appointment.status),

          // More options
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, size: 16, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status.toLowerCase()) {
      case 'scheduled':
        color = const Color(0xFF1A73E8);
        bg = const Color(0xFFE8F0FE);
        break;
      case 'completed':
        color = const Color(0xFF34A853);
        bg = const Color(0xFFE6F4EA);
        break;
      case 'cancelled':
        color = AppTheme.error;
        bg = const Color(0xFFFCE8E6);
        break;
      default:
        color = AppTheme.textSecondary;
        bg = AppTheme.background;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Mobile list view ─────────────────────────────────────────────────────────

class _MobileAppointmentList extends StatelessWidget {
  final List<_Appointment> appointments;
  const _MobileAppointmentList({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: appointments.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, i) {
        final a = appointments[i];
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${a.time} • ${a.service}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      a.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: a.status),
            ],
          ),
        );
      },
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _Appointment {
  final String patientName;
  final String service;
  final String time;
  final String date;
  final String status;
  final int hour;

  const _Appointment({
    required this.patientName,
    required this.service,
    required this.time,
    required this.date,
    required this.status,
    required this.hour,
  });
}

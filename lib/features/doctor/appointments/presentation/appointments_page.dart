// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';

/// Doctor Appointments page matching Figma "List of appointments".
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int _selectedTab = 0;
  String _viewMode = 'Day';

  final List<_AppointmentData> _appointments = [
    const _AppointmentData(
      time: '11:00-12:00',
      date: '26 Apr 2026',
      service: 'Treatment of diabetes',
      patient: 'Prince Mashumu',
      status: 'Scheduled',
      hour: 9,
      cardColor: Color(0xFFA382FE),
      borderColor: Color(0xFF992D9D),
    ),
    const _AppointmentData(
      time: '11:00-12:00',
      date: '26 Apr 2026',
      service: 'Treatment of diabetes',
      patient: 'Maria Wilson',
      status: 'Scheduled',
      hour: 10,
    ),
    const _AppointmentData(
      time: '11:00-12:00',
      date: '26 Apr 2026',
      service: 'Treatment of diabetes',
      patient: 'Maria Wilson',
      status: 'Scheduled',
      hour: 12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF6DD0D8).withOpacity(0.15),
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
                        child: SingleChildScrollView(
                          child: _TimeGrid(appointments: _appointments),
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
                Image.asset('assets/icons/calender.png',
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
  final List<_AppointmentData> appointments;

  @override
  Widget build(BuildContext context) {
    const hours = [9, 10, 11, 12];
    const hourLabels = ['9 am', '10 am', '11 am', '12 am'];

    return Column(
      children: List.generate(hours.length, (i) {
        final hour = hours[i];
        final label = hourLabels[i];
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
  final _AppointmentData data;

  @override
  Widget build(BuildContext context) {
    const tealLight = Color(0xFFE0F5F5);
    const tealBorder = Color(0xFF309CA3);

    final bgColor = data.cardColor?.withOpacity(0.2) ?? tealLight;
    final leftBorder = data.borderColor ?? tealBorder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
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
                  data.time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.date,
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
                Text(data.service,
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
                Text(data.patient,
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
              _StatusBadge(status: data.status),
            ],
          ),

        

          // Action icon
          Image.asset(
            'assets/icons/arrow-actions-icon.png',
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

// ─── Data model ───────────────────────────────────────────────────────────────

class _AppointmentData {

  const _AppointmentData({
    required this.time,
    required this.date,
    required this.service,
    required this.patient,
    required this.status,
    required this.hour,
    this.cardColor,
    this.borderColor,
  });
  final String time;
  final String date;
  final String service;
  final String patient;
  final String status;
  final int hour;
  final Color? cardColor;
  final Color? borderColor;
}

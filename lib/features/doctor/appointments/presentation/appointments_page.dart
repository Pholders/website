// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int _selectedTab = 0;
  String _viewMode = 'Day';
  DateTime _focusedDate = DateTime(2026, 4, 15);

  final List<_AppointmentData> _appointments = const [
    _AppointmentData(
      time: '11:00-12:00',
      date: '26 Apr 2026',
      service: 'Treatment of diabetes',
      patient: 'Prince Mashumu',
      status: 'Scheduled',
      hour: 9,
      cardColor: Color(0xFFA382FE),
      borderColor: Color(0xFF992D9D),
    ),
    _AppointmentData(
      time: '11:00-12:00',
      date: '26 Apr 2026',
      service: 'Treatment of diabetes',
      patient: 'Maria Wilson',
      status: 'Scheduled',
      hour: 10,
    ),
    _AppointmentData(
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
                'Stay organized and on track with calendar',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              _TabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: 20),
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
                        focusedDate: _focusedDate,
                        viewMode: _viewMode,
                        onPrevious: () =>
                            setState(() => _focusedDate = _shiftDate(-1)),
                        onNext: () =>
                            setState(() => _focusedDate = _shiftDate(1)),
                        onPickDate: _pickDate,
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

  DateTime _shiftDate(int direction) {
    final days = _viewMode == 'Month'
        ? 30
        : _viewMode == 'Week'
            ? 7
            : 1;
    return _focusedDate.add(Duration(days: days * direction));
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (selected != null) {
      setState(() => _focusedDate = selected);
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedIndex, required this.onTabChanged});

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Future visits(20)', 'Past visits', 'Planned Treatments'];
    const activeColor = Color(0xFF309CA3);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSelected ? activeColor : AppTheme.textSecondary,
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focusedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
    required this.onViewModeChanged,
  });

  final DateTime focusedDate;
  final String viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final ValueChanged<String> onViewModeChanged;

  String get _dateLabel => '${focusedDate.day} $_monthName ${focusedDate.year}';

  String get _shortDateLabel => '${focusedDate.day} $_monthName';

  String get _monthName {
    const months = [
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
    return months[focusedDate.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final dateControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Previous',
              icon: const Icon(
                Icons.chevron_left,
                size: 22,
                color: AppTheme.textSecondary,
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Next',
              icon: const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _dateLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        );

        final controls = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewToggle(selected: viewMode, onChanged: onViewModeChanged),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPickDate,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/calender.png',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _shortDateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateControls,
                    const SizedBox(height: 10),
                    controls,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: dateControls),
                    controls,
                  ],
                ),
        );
      },
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
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
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

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({required this.appointments});

  final List<_AppointmentData> appointments;

  @override
  Widget build(BuildContext context) {
    const hours = [9, 10, 11, 12];
    const hourLabels = ['9 am', '10 am', '11 am', '12 pm'];

    return Column(
      children: List.generate(hours.length, (i) {
        final hour = hours[i];
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
                    hourLabels[i],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.divider),
              Expanded(
                child: appts.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
      constraints: const BoxConstraints(maxWidth: 580, minWidth: 540),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening appointment for ${data.patient}')),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: leftBorder, width: 3)),
          ),
          child: Row(
            children: [
              _CardField(
                width: 100,
                label: data.time,
                value: data.date,
                labelColor: AppTheme.textPrimary,
              ),
              const _CardDivider(),
              _CardField(label: 'Service', value: data.service),
              const _CardDivider(),
              _CardField(label: 'Patient', value: data.patient),
              const _CardDivider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: data.status),
                ],
              ),
              const Spacer(),
              Image.asset(
                'assets/icons/arrow-actions-icon.png',
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

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
    this.width = 120,
    this.labelColor = AppTheme.textSecondary,
  });

  final String label;
  final String value;
  final double width;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: labelColor == AppTheme.textPrimary ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.divider,
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
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

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

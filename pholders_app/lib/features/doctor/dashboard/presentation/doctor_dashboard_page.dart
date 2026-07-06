import 'package:flutter/material.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  bool showAlert = true;
  String selectedTrend = 'Monthly';
  String selectedPatientFilter = 'All';
  final DateTime dashboardDate = DateTime(2026, 3, 14);

  final List<Map<String, dynamic>> appointments = const [
    {'time': '08:00', 'patient': 'Maria Wilson', 'duration': '08:25 - 09:00'},
    {'time': '09:00', 'patient': 'Maria Wilson', 'duration': '09:45 - 10:30'},
    {'time': '11:00', 'patient': 'Maria Wilson', 'duration': '11:20 - 11:45'},
    {'time': '14:00', 'patient': 'Maria Wilson', 'duration': '14:20 - 14:45'},
  ];

  final List<Map<String, dynamic>> patients = [
    {
      'name': 'Maria Wilson',
      'condition': 'Acne Treatment',
      'activity': '2 hours ago',
      'status': 'Attention Needed',
      'priority': 'High',
      'type': 'All',
      'avatar': 'assets/doctors.png',
    },
    {
      'name': 'Maria Wilson',
      'condition': 'Statin therapy',
      'activity': '2 hours ago',
      'status': 'Monitored',
      'priority': 'Low',
      'type': 'Outpatients',
      'avatar': 'assets/doctors.png',
    },
  ];

  static const Color primaryTeal = Color(0xFF48BFC4);
  static const Color darkTeal = Color(0xFF2E9FA5);
  static const Color lightTealBg = Color(0xFFE4F8F9);
  static const Color cardMint = Color(0xFFE2F6F7);
  static const Color pageText = Color(0xFF102025);
  static const Color orange = Color(0xFFFFA51E);
  static const Color lavender = Color(0xFFEDE3FF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
              ? _compactLayout()
              : SizedBox(height: dashboardHeight, child: _desktopLayout()),
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
    );
  }

  Widget _desktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 255, child: _appointmentsSection()),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 124, child: _statsRow()),
                    const SizedBox(height: 14),
                    Expanded(child: _activitySection()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(flex: 2, child: _patientsSection()),
      ],
    );
  }

  Widget _compactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(),
        const SizedBox(height: 12),
        SizedBox(height: 280, child: _appointmentsSection()),
        const SizedBox(height: 14),
        SizedBox(height: 124, child: _statsRow()),
        const SizedBox(height: 14),
        SizedBox(height: 210, child: _activitySection()),
        const SizedBox(height: 14),
        SizedBox(height: 180, child: _patientsSection()),
      ],
    );
  }

  Widget _headerRow() {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dashboardDateLabel,

          style: const TextStyle(
            fontSize: 12,

            color: Color(0xFF7C8B8D),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Good Morning Doctor',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Color(0xFF102025),
          ),
        ),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAlert) _alertPill(),
        const SizedBox(height: 10),
        _dashboardMenu(),
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
              Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }

  Widget _alertPill() {
    return Container(
      width: 280,
      height: 24,
      padding: const EdgeInsets.only(left: 8),
      color: const Color(0xFFFFE760),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Prince Mashumu skipped medication for 2 days',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8, color: Color(0xFF9B8500)),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 24),
            icon: const Icon(Icons.more_horiz, size: 15, color: Colors.black),
            onSelected: (value) {
              if (value == 'dismiss') setState(() => showAlert = false);
              if (value == 'snooze') _message('Alert snoozed for 1 hour');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'dismiss', child: Text('Dismiss alert')),
              PopupMenuItem(value: 'snooze', child: Text('Snooze for 1 hour')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Dashboard options',
      icon: const Icon(
        Icons.dashboard_customize,
        size: 22,
        color: Colors.black,
      ),
      onSelected: (value) {
        if (value == 'refresh') _message('Dashboard refreshed');
        if (value == 'customize') _message('Customize dashboard selected');
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'refresh', child: Text('Refresh dashboard')),
        PopupMenuItem(value: 'customize', child: Text('Customize widgets')),
      ],
    );
  }

  Widget _statsRow() {
    return _tealCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowWidth = constraints.maxWidth < 520
              ? 520.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: rowWidth,
              child: Row(
                children: [
                  _statTile(
                    Icons.calendar_month,
                    'Appointments',
                    '72',
                    '+12%',
                    'vs last month',
                  ),
                  _statDivider(),
                  _statTile(
                    Icons.person,
                    'Patients',
                    '100+',
                    '+12%',
                    'vs last month',
                  ),
                  _statDivider(),
                  _statTile(
                    Icons.reviews,
                    'Reviews',
                    '10+',
                    '*****',
                    'Last updated 06:30',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(
    IconData icon,
    String label,
    String value,
    String meta,
    String subtext,
  ) {
    final isReview = label == 'Reviews';

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _message('$label opened'),
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
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
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
                Text(
                  meta,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    subtext,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ),
              ] else
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 8,
                      color: Color(0xFF24C35B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF24C35B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtext,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF9A9A9A),
                        ),
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

  Widget _appointmentsSection() {
    return _tealCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Appointments',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Mar 14th',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _timelineAxis(),
                const SizedBox(width: 8),
                Expanded(child: _appointmentTimeline()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentTimeline() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const startHour = 8;
        const endHour = 15;
        const cardHeight = 38.0;
        final timelineHeight = constraints.maxHeight;
        final minuteHeight = timelineHeight / ((endHour - startHour) * 60);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < appointments.length; i++)
              _positionedAppointment(
                appointments[i],
                i,
                cardHeight,
                minuteHeight,
                startHour,
                timelineHeight,
              ),
          ],
        );
      },
    );
  }

  Widget _positionedAppointment(
    Map<String, dynamic> appt,
    int index,
    double cardHeight,
    double minuteHeight,
    int startHour,
    double timelineHeight,
  ) {
    final start = _appointmentStartMinutes(appt['duration']);
    final top = ((start - startHour * 60) * minuteHeight)
        .clamp(0.0, timelineHeight - cardHeight)
        .toDouble();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: cardHeight,
      child: _appointmentCard(appt, index),
    );
  }

  int _appointmentStartMinutes(String duration) {
    final start = duration.split('-').first.trim();
    final parts = start.split(':');
    if (parts.length != 2) return 8 * 60;

    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  Widget _timelineAxis() {
    const times = [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
    ];

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
                for (final time in times)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF8C9A9D),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 1, color: const Color(0xFFC6D4D6)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: primaryTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt, int index) {
    final isFirst = index == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showAppointmentDetails(appt),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 6, 9, 6),
        decoration: BoxDecoration(
          color: isFirst ? lavender : cardMint,
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
                    appt['patient'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    appt['duration'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF7A8B8E),
                    ),
                  ),
                ],
              ),
            ),
            if (isFirst)
              const Icon(Icons.medication, size: 12, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _activitySection() {
    final labels = _trendLabels();
    final values = _trendValues(labels.length);

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
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _trendChip('Daily'),
                      _trendChip('Monthly'),
                      _trendChip('Yearly'),
                      IconButton(
                        tooltip: 'Pick date range',
                        onPressed: () async {
                          await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                        },
                        icon: const Icon(Icons.calendar_month, size: 13),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '80',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        '60',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        '40',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        '20',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        '0',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Column(
                            children: [
                              for (var i = 0; i < 5; i++) ...[
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
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < labels.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Stack(
                                              alignment: Alignment.bottomCenter,
                                              children: [
                                                Container(
                                                  width: 26,
                                                  decoration: BoxDecoration(
                                                    color: cardMint,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                ),
                                                FractionallySizedBox(
                                                  heightFactor: values[i],
                                                  child: Container(
                                                    width: 26,
                                                    decoration: BoxDecoration(
                                                      color: darkTeal,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          labels[i],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
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

  List<String> _trendLabels() {
    if (selectedTrend == 'Daily') {
      return const ['00', '03', '06', '09', '12', '15', '18'];
    }
    if (selectedTrend == 'Yearly') {
      return const ['2020', '2021', '2022', '2023', '2024', '2025'];
    }
    return const [
      'Jan',
      'Feb',
      'Apr',
      'Mar',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Oct',
      'Nov',
      'Dec',
    ];
  }

  List<double> _trendValues(int length) {
    final base = selectedTrend == 'Daily'
        ? <double>[.54, .66, .48, .73, .61, .42, .69]
        : selectedTrend == 'Yearly'
        ? <double>[.44, .55, .63, .71, .78, .83]
        : <double>[.72, .72, .72, .72, .52, .72, .72, .72, .72, .72, .72];
    return base.take(length).toList();
  }

  String get _dashboardDateLabel {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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

    return '${weekdays[dashboardDate.weekday - 1]}, '
        '${dashboardDate.day}${_ordinalSuffix(dashboardDate.day)} '
        '${months[dashboardDate.month - 1]}';
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

  Widget _trendChip(String text) {
    final selected = selectedTrend == text;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => selectedTrend = text),
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

  Widget _patientsSection() {
    final visiblePatients = selectedPatientFilter == 'All'
        ? patients
        : patients
              .where((patient) => patient['type'] == selectedPatientFilter)
              .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 824
            ? 780.0
            : constraints.maxWidth - 44;

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
                        'Patients',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 28),
                      _filterChip('All'),
                      _filterChip('Outpatients'),
                      _filterChip('Remote care'),
                      _filterChip('Follow-up'),
                      const Spacer(),
                      _filterButton(),
                      const SizedBox(width: 10),
                      _addButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _patientHeader(tableWidth),
              const SizedBox(height: 8),
              Expanded(
                child: visiblePatients.isEmpty
                    ? const Center(
                        child: Text(
                          'No patients for this filter',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visiblePatients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _patientRow(visiblePatients[index], tableWidth),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String text) {
    final selected = selectedPatientFilter == text;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => selectedPatientFilter = text),
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

  Widget _filterButton() {
    return PopupMenuButton<String>(
      tooltip: 'Filter patients',
      onSelected: (value) => setState(() => selectedPatientFilter = value),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'All', child: Text('All')),
        PopupMenuItem(value: 'Outpatients', child: Text('Outpatients')),
        PopupMenuItem(value: 'Remote care', child: Text('Remote care')),
        PopupMenuItem(value: 'Follow-up', child: Text('Follow-up')),
      ],
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFE5E5E5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.tune, size: 18, color: Colors.black),
      ),
    );
  }

  Widget _addButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showAddPatientDialog,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
        child: const Icon(Icons.add, size: 23, color: Colors.black),
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
            Expanded(flex: 2, child: _HeaderText('Name')),
            Expanded(flex: 2, child: _HeaderText('Condition')),
            Expanded(flex: 2, child: _HeaderText('Last activity')),
            Expanded(flex: 2, child: _HeaderText('Status')),
            Expanded(flex: 1, child: _HeaderText('Priority')),
            SizedBox(width: 96),
          ],
        ),
      ),
    );
  }

  Widget _patientRow(Map<String, dynamic> patient, double tableWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showPatientDetails(patient),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _patientAvatar(patient),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        patient['name'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  patient['condition'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  patient['activity'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
                ),
              ),
              Expanded(flex: 2, child: _statusChip(patient['status'])),
              Expanded(flex: 1, child: _priorityText(patient['priority'])),
              SizedBox(
                width: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Edit patient',
                      onPressed: () => _showEditPatientDialog(patient),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF6C6C6C),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 22,
                        height: 22,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete patient',
                      onPressed: () => _deletePatient(patient),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFF6C6C6C),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 22,
                        height: 22,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Patient menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 22,
                        height: 22,
                      ),
                      icon: const Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Color(0xFF6C6C6C),
                      ),
                      onSelected: (value) =>
                          _message('$value: ${patient['name']}'),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'View profile',
                          child: Text('View profile'),
                        ),
                        PopupMenuItem(
                          value: 'Send reminder',
                          child: Text('Send reminder'),
                        ),
                        PopupMenuItem(
                          value: 'Create prescription',
                          child: Text('Create prescription'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _patientAvatar(Map<String, dynamic> patient) {
    final avatar = patient['avatar'] as String?;

    if (avatar == null || avatar.isEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: primaryTeal,
        child: Text(
          _initials(patient['name']),
          style: const TextStyle(fontSize: 8, color: Colors.white),
        ),
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: cardMint,
      backgroundImage: AssetImage(avatar),
    );
  }

  Widget _statusChip(String status) {
    final isAttention = status == 'Attention Needed';
    final bg = isAttention ? const Color(0xFFFF7777) : const Color(0xFFFFD36D);
    final text = isAttention
        ? const Color(0xFFFF1D25)
        : const Color(0xFFFFA000);

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: bg.withOpacity(.85),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: text, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(status, style: TextStyle(fontSize: 9, color: text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityText(String priority) {
    final color = priority == 'High' ? darkTeal : const Color(0xFF00A1A6);
    return Text(priority, style: TextStyle(fontSize: 9, color: color));
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

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment['patient'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text('Time: ${appointment['duration']}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _message('Appointment opened');
                    },
                    child: const Text('Open'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(patient['name']),
        content: Text(
          'Condition: ${patient['condition']}\nStatus: ${patient['status']}\nPriority: ${patient['priority']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final conditionController = TextEditingController();
    String type = 'Outpatients';
    String priority = 'Low';

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Patient'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Patient name'),
                ),
                TextField(
                  controller: conditionController,
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Care type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Outpatients',
                      child: Text('Outpatients'),
                    ),
                    DropdownMenuItem(
                      value: 'Remote care',
                      child: Text('Remote care'),
                    ),
                    DropdownMenuItem(
                      value: 'Follow-up',
                      child: Text('Follow-up'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? type),
                ),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => priority = value ?? priority),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  setState(() {
                    patients.add({
                      'name': nameController.text.trim(),
                      'condition': conditionController.text.trim().isEmpty
                          ? 'General care'
                          : conditionController.text.trim(),
                      'activity': 'Just now',
                      'status': priority == 'High'
                          ? 'Attention Needed'
                          : 'Monitored',
                      'priority': priority,
                      'type': type,
                    });
                  });
                  Navigator.pop(context);
                  _message('Patient added');
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPatientDialog(Map<String, dynamic> patient) {
    final nameController = TextEditingController(text: patient['name']);
    final conditionController = TextEditingController(
      text: patient['condition'],
    );
    String priority = patient['priority'];

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Patient'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Patient name'),
                ),
                TextField(
                  controller: conditionController,
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => priority = value ?? priority),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    patient['name'] = nameController.text.trim();
                    patient['condition'] = conditionController.text.trim();
                    patient['priority'] = priority;
                    patient['status'] = priority == 'High'
                        ? 'Attention Needed'
                        : 'Monitored';
                  });
                  Navigator.pop(context);
                  _message('Patient updated');
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePatient(Map<String, dynamic> patient) {
    setState(() => patients.remove(patient));
    _message('Patient removed');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

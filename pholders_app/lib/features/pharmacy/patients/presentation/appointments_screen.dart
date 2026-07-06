import 'package:flutter/material.dart';
import 'package:doctor_app/screens/patients_screen.dart' show Patient;

// ─── Colors ───────────────────────────────────────────────────────────────────
class ApptColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const cardBg = Color(0xFFFFFFFF);
  static const scheduledBg = Color(0xFFD9F3F3);
  static const scheduledText = Color(0xFF2EC4C4);
  static const purple = Color(0xFF9B59B6);
  static const purpleLight = Color(0xFFF3E8FF);
}

// ─── Data model ───────────────────────────────────────────────────────────────
class Appointment {
  final String id;
  final String time;
  final String date;
  final String service;
  final String doctor;
  final String status;
  final int hour; // for timeline placement
  final bool isPurple; // alternates colours

  const Appointment({
    required this.id,
    required this.time,
    required this.date,
    required this.service,
    required this.doctor,
    required this.status,
    required this.hour,
    this.isPurple = false,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────
final _mockAppointments = [
  const Appointment(id: 'A1', time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled', hour: 9, isPurple: true),
  const Appointment(id: 'A2', time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled', hour: 10, isPurple: false),
  const Appointment(id: 'A3', time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled', hour: 12, isPurple: false),
];

// ─── Appointments Screen ──────────────────────────────────────────────────────
class AppointmentsScreen extends StatefulWidget {
  final Patient patient;

  const AppointmentsScreen({super.key, required this.patient});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _visitTab = 0; // 0=Future visits, 1=Past Visits, 2=Planned Treatments
  int _viewMode = 0; // 0=Day, 1=Week, 2=Month
  DateTime _currentDate = DateTime(2026, 4, 15);

  static const _visitTabs = ['Future visits (2)', 'Past Visits (15)', 'Planned Treatments'];
  static const _viewModes = ['Day', 'Week', 'Month'];

  void _prevDay() => setState(() => _currentDate = _currentDate.subtract(const Duration(days: 1)));
  void _nextDay() => setState(() => _currentDate = _currentDate.add(const Duration(days: 1)));

  String get _formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_currentDate.day} ${months[_currentDate.month - 1]} ${_currentDate.year}';
  }

  String get _shortDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_currentDate.day} ${months[_currentDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: ApptColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ApptColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Visit tabs ───────────────────────────────────────────────────
            Row(
              children: List.generate(_visitTabs.length, (i) {
                final active = i == _visitTab;
                return GestureDetector(
                  onTap: () => setState(() => _visitTab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active
                              ? ApptColors.teal
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _visitTabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: active
                            ? ApptColors.teal
                            : ApptColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ── Controls row: date nav + view mode + date picker ─────────────
            Row(
              children: [
                // Prev / Next arrows
                GestureDetector(
                  onTap: _prevDay,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ApptColors.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ApptColors.border),
                    ),
                    child: const Icon(Icons.chevron_left,
                        size: 18, color: ApptColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _nextDay,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ApptColors.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ApptColors.border),
                    ),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: ApptColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),

                // Current date label
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ApptColors.textPrimary,
                  ),
                ),

                const Spacer(),

                // Day / Week / Month toggle
                Container(
                  decoration: BoxDecoration(
                    color: ApptColors.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ApptColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_viewModes.length, (i) {
                      final active = i == _viewMode;
                      return GestureDetector(
                        onTap: () => setState(() => _viewMode = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? ApptColors.teal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _viewModes[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : ApptColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 12),

                // Date picker button
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _currentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: ApptColors.teal),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _currentDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ApptColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ApptColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: ApptColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _shortDate,
                          style: const TextStyle(
                              fontSize: 13,
                              color: ApptColors.textPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Timeline ─────────────────────────────────────────────────────
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  // ── Timeline view ─────────────────────────────────────────────────────────
  Widget _buildTimeline() {
    final hours = List.generate(8, (i) => i + 9); // 9am to 4pm

    return Column(
      children: hours.map((hour) {
        final appts = _mockAppointments
            .where((a) => a.hour == hour)
            .toList();

        return _TimelineRow(
          hour: hour,
          appointments: appts,
        );
      }).toList(),
    );
  }
}

// ─── Timeline row ─────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final int hour;
  final List<Appointment> appointments;

  const _TimelineRow({required this.hour, required this.appointments});

  String get _hourLabel {
    if (hour == 12) return '12 pm';
    if (hour > 12) return '${hour - 12} pm';
    return '$hour am';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour label
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _hourLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: ApptColors.textSecondary,
                ),
              ),
            ),
          ),

          // Divider + content area
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: ApptColors.border),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: appointments.isEmpty
                  ? const SizedBox()
                  : Column(
                      children: appointments
                          .map((a) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _AppointmentCard(appt: a),
                              ))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment card ─────────────────────────────────────────────────────────
class _AppointmentCard extends StatefulWidget {
  final Appointment appt;
  const _AppointmentCard({required this.appt});

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.appt;
    final bgColor =
        a.isPurple ? ApptColors.purpleLight : ApptColors.tealLight;
    final accentColor =
        a.isPurple ? ApptColors.purple : ApptColors.teal;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? bgColor.withOpacity(0.8) : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
        ),
        child: Row(
          children: [
            // Time + date
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.time,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor)),
                  const SizedBox(height: 2),
                  Text(a.date,
                      style: const TextStyle(
                          fontSize: 11,
                          color: ApptColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Service
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service',
                      style: TextStyle(
                          fontSize: 10,
                          color: ApptColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(a.service,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ApptColors.textPrimary)),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Doctor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Doctor',
                      style: TextStyle(
                          fontSize: 10,
                          color: ApptColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(a.doctor,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ApptColors.textPrimary)),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status',
                    style: TextStyle(
                        fontSize: 10,
                        color: ApptColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: ApptColors.scheduledBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.status,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ApptColors.scheduledText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

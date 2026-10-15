import 'package:flutter/material.dart';

import '../data/doctor_patient.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart' show Patient, PatientStatus;
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';

// ─── Patient Profile Screen ───────────────────────────────────────────────────
class PatientProfileScreen extends StatefulWidget {

  const PatientProfileScreen({
    super.key,
    required this.patient,
    required this.onBack,
  });
  final Patient patient;
  final VoidCallback onBack;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  int _tabIndex = 0;
  int _visitTabIndex = 0;

  static const _profileTabs = [
    'Patient profile',
    'Medication',
    'Prescriptions',
    'Appointments',
    'Documents',
    'History',
  ];

  static const _visitTabs = [
    'Future visits (2)',
    'Past Visits (15)',
    'Planned Treatments',
  ];

  // Mock vitals
  final _vitals = [
    const _Vital(icon: Icons.favorite_rounded, label: 'Blood Pressure', value: '180/20', unit: 'mmHg', status: 'In the norm', isNorm: true),
    const _Vital(icon: Icons.monitor_heart_outlined, label: 'Heart Rate', value: '120', unit: 'bpm', status: 'Above the norm', isNorm: false),
    const _Vital(icon: Icons.accessibility_new_rounded, label: 'Body Weight', value: '74', unit: 'kg', status: 'In the norm', isNorm: true),
    const _Vital(icon: Icons.water_drop_outlined, label: 'Cholesterol', value: '130', unit: 'mg/dl', status: 'Above the norm', isNorm: false),
  ];

  // Mock visits
  final _visits = [
    const _Visit(time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled'),
    const _Visit(time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled'),
    const _Visit(time: '11:00–12:00', date: '26 Apr 2026', service: 'Treatment of diabetes', doctor: 'Dr Sam Smith', status: 'Scheduled'),
  ];

  // Mock timeline
  final _timeline = [
    const _TimelineItem(date: 'Dec 2024', label: 'Pre-diabetic'),
    const _TimelineItem(date: 'Jan 2024', label: 'Type 2'),
    const _TimelineItem(date: 'Dec 2023', label: 'Chronic thyroid disorder'),
    const _TimelineItem(date: 'Jul 2022', label: 'Angina Pectoris'),
    const _TimelineItem(date: 'Jun 2021', label: 'Chronic Flu'),
    const _TimelineItem(date: 'Jun 2021', label: 'Chronic Flu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        // ── Tab bar pinned — lives OUTSIDE the scroll view so it never scrolls away
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildProfileTabs(),
              const Divider(height: 1, thickness: 1, color: AppProfileColors.border),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppProfileColors.bg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tab content ──────────────────────────────────────────
                  if (_tabIndex == 0) ...[
                    const SizedBox(height: 20),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildVisitsCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildTimelineCard()),
                      ],
                    ),
                  ] else if (_tabIndex == 1) ...[
                    const SizedBox(height: 20),
                    MedicationScreen(patient: widget.patient),
                  ] else if (_tabIndex == 2) ...[
                    const SizedBox(height: 20),
                    PrescriptionsScreen(patient: widget.patient),
                  ] else if (_tabIndex == 3) ...[
                    const SizedBox(height: 20),
                    AppointmentsScreen(patient: widget.patient),
                  ] else if (_tabIndex == 4) ...[
                    const SizedBox(height: 20),
                    DocumentsScreen(patient: widget.patient),
                  ] else if (_tabIndex == 5) ...[
                    const SizedBox(height: 20),
                    MedicalHistoryScreen(patient: widget.patient),
                  ] else ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        '${_profileTabs[_tabIndex]} — coming soon',
                        style: const TextStyle(
                            color: AppProfileColors.textSecondary,
                            fontSize: 15),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, color: AppProfileColors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.patient.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppProfileColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
                    Expanded(
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppProfileColors.border),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for patient name, ID, or prescription...',
                    hintStyle: TextStyle(color: AppProfileColors.textSecondary, fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 18, color: AppProfileColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppProfileColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppProfileColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile tabs ─────────────────────────────────────────────────────────────
  Widget _buildProfileTabs() {
    return Row(
      children: List.generate(_profileTabs.length, (i) {
        final active = i == _tabIndex;
        return GestureDetector(
          onTap: () => setState(() => _tabIndex = i),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? AppProfileColors.teal : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              _profileTabs[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppProfileColors.teal : AppProfileColors.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppProfileColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: avatar + name + email + edit
          SizedBox(
            width: 200,
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppProfileColors.tealLight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.person, size: 80, color: AppProfileColors.teal),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.patient.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppProfileColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.patient.email ?? 'No email on file',
                  style: const TextStyle(color: AppProfileColors.teal, fontSize: 12),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppProfileColors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  ),
                  child: const Text('Edit', style: TextStyle(color: AppProfileColors.teal)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // Right: info grid + vitals
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info grid
                const Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: const [
                    _InfoField(label: 'Gender', value: 'Female'),
                    _InfoField(label: 'Age', value: '32'),
                    _InfoField(label: 'Blood', value: '0'),
                    _InfoField(label: 'Status', value: 'Active'),
                    _InfoField(label: 'Department', value: 'Cardiology'),
                    _InfoField(label: 'Registered Date', value: '15/02/2026'),
                    _InfoField(label: 'Appointment', value: '32'),
                    _InfoField(label: 'Bed No.', value: '#00125'),
                  ],
                ),

                const SizedBox(height: 20),

                // Vitals label
                const Text('Vitals',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppProfileColors.textSecondary)),
                const SizedBox(height: 12),

                // Vitals row
                Row(
                  children: _vitals.map((v) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _VitalCard(vital: v),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Visits card ──────────────────────────────────────────────────────────────
  Widget _buildVisitsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppProfileColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visit tabs
          Row(
            children: List.generate(_visitTabs.length, (i) {
              final active = i == _visitTabIndex;
              return GestureDetector(
                onTap: () => setState(() => _visitTabIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? AppProfileColors.teal : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _visitTabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppProfileColors.teal : AppProfileColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Date header
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppProfileColors.textSecondary),
              SizedBox(width: 6),
              Text('Today, 21 Feb 2026',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppProfileColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),

          const SizedBox(height: 12),

          // Visit rows
          ..._visits.asMap().entries.map((e) {
            final isFirst = e.key == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VisitRow(visit: e.value, highlight: isFirst),
            );
          }),
        ],
      ),
    );
  }

  // ── Timeline card ────────────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppProfileColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 18, color: AppProfileColors.teal),
              const SizedBox(width: 8),
              const Text('Timeline',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppProfileColors.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Edit',
                    style: TextStyle(color: AppProfileColors.teal, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._timeline.asMap().entries.map((e) {
            final isLast = e.key == _timeline.length - 1;
            return _TimelineRow(item: e.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppProfileColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const normGreen = Color(0xFF2EC4C4);
  static const aboveRed = Color(0xFFFF6B6B);
  static const normBg = Color(0xFFE6F7F7);
  static const aboveBg = Color(0xFFFFEEEE);
  static const scheduledBg = Color(0xFFD9F3F3);
  static const purple = Color(0xFF9B59B6);
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _Vital {
  const _Vital({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.isNorm,
  });
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String status;
  final bool isNorm;
}

class _Visit {
  const _Visit({
    required this.time,
    required this.date,
    required this.service,
    required this.doctor,
    required this.status,
  });
  final String time;
  final String date;
  final String service;
  final String doctor;
  final String status;
}

class _TimelineItem {
  const _TimelineItem({required this.date, required this.label});
  final String date;
  final String label;
}

// ─── Info field ───────────────────────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppProfileColors.textSecondary,
                  fontWeight: FontWeight.w400)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppProfileColors.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Vital card ───────────────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  const _VitalCard({required this.vital});
  final _Vital vital;

  @override
  Widget build(BuildContext context) {
    final color = vital.isNorm ? AppProfileColors.normGreen : AppProfileColors.aboveRed;
    final bg = vital.isNorm ? AppProfileColors.normBg : AppProfileColors.aboveBg;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(vital.icon, size: 18, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(vital.label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppProfileColors.textSecondary)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: vital.value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppProfileColors.textPrimary)),
                TextSpan(
                    text: ' ${vital.unit}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppProfileColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(vital.status,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Visit row ────────────────────────────────────────────────────────────────
class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, required this.highlight});
  final _Visit visit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppProfileColors.purple.withValues(alpha: 0.08)
            : AppProfileColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: highlight ? AppProfileColors.purple : AppProfileColors.teal,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Time + date
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.time,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppProfileColors.textPrimary)),
                Text(visit.date,
                    style: const TextStyle(
                        fontSize: 11, color: AppProfileColors.textSecondary)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Service
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service',
                    style: TextStyle(
                        fontSize: 10, color: AppProfileColors.textSecondary)),
                Text(visit.service,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppProfileColors.textPrimary)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Doctor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Doctor',
                    style: TextStyle(
                        fontSize: 10, color: AppProfileColors.textSecondary)),
                Text(visit.doctor,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppProfileColors.textPrimary)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status',
                  style: TextStyle(
                      fontSize: 10, color: AppProfileColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppProfileColors.scheduledBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Scheduled',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppProfileColors.teal)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Timeline row ─────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});
  final _TimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label
          SizedBox(
            width: 60,
            child: Text(item.date,
                style: const TextStyle(
                    fontSize: 10, color: AppProfileColors.textSecondary)),
          ),

          // Dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppProfileColors.teal,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppProfileColors.border,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(item.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppProfileColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

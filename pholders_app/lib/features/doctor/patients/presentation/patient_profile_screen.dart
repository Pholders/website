import 'package:flutter/material.dart';

import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart' show Patient;
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_vitals_panel.dart';

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

  static const _profileTabs = [
    'Patient profile',
    'Medication',
    'Prescriptions',
    'Appointments',
    'Documents',
    'History',
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
                    // A scheduled-visits list and a diagnosis timeline used to
                    // sit here, both filled with invented entries — three
                    // identical diabetes appointments, and a history running
                    // back to 2021 — shown against whichever real patient had
                    // been opened.
                    const _RecordNotice(
                      title: 'Past and planned visits',
                      detail: 'Their bookings with you are under the '
                          'Appointments tab. A full visit history across every '
                          'doctor is part of the patient’s own record, which is '
                          'a later phase.',
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
              ],
            ),
          ),

          const SizedBox(width: 32),

          // Right: info grid + vitals
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only what a booking actually tells us. Gender, age, blood
                // group, department and a bed number used to be printed here
                // as fixed values, so every real patient read as a 32-year-old
                // woman in Cardiology on bed #00125.
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _InfoField(
                        label: 'Email',
                        value: widget.patient.email ?? 'Not given'),
                    _InfoField(
                        label: 'Phone',
                        value: widget.patient.phone ?? 'Not given'),
                    _InfoField(
                        label: 'Last visit',
                        value: widget.patient.lastActivity),
                    _InfoField(
                        label: 'Reason', value: widget.patient.condition),
                  ],
                ),

                const SizedBox(height: 20),

                PatientVitalsPanel(patientId: widget.patient.id),
              ],
            ),
          ),
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

// ─── Record notice ────────────────────────────────────────────────────────────

/// Stands where invented clinical data used to be drawn, and says plainly
/// that there is nothing here rather than filling the space with a number.
class _RecordNotice extends StatelessWidget {
  const _RecordNotice({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppProfileColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppProfileColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppProfileColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppProfileColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

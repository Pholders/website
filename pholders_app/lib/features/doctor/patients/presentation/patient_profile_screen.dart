import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_overview.dart';
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
    'Vitals',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        // As in the design, the tabs and what they show share one pale teal
        // panel on the white page. The tabs stay put; the content scrolls.
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              decoration: BoxDecoration(
                color: _panelBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _buildProfileTabs(),
                  ),
                  Expanded(child: _tabContent()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabContent() {
    // The profile tab fills the panel, so its visit and timeline panels
    // reach the bottom; it scrolls only when the window is shorter than the
    // overview needs.
    return _tabIndex == 0
        ? LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: PatientOverview(
                patient: widget.patient,
                framed: false,
                height: math.max(c.maxHeight, PatientOverview.minHeight),
              ),
            ),
          )
        : _tabIndex == 1
            // The medication history scrolls inside its own card, so the
            // tab is given the panel's height like the profile tab.
            ? LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: MedicationScreen(
                    patient: widget.patient,
                    height:
                        math.max(c.maxHeight - 36, MedicationScreen.minHeight),
                  ),
                ),
              )
            : _tabIndex >= 2 && _tabIndex <= 6
                // These tabs scroll inside their cards, under fixed
                // headers, so they are given the panel's height.
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: switch (_tabIndex) {
                      2 => PrescriptionsScreen(patient: widget.patient),
                      3 => AppointmentsScreen(patient: widget.patient),
                      4 => DocumentsScreen(patient: widget.patient),
                      5 => MedicalHistoryScreen(patient: widget.patient),
                      _ => PatientVitalsPanel(patientId: widget.patient.id),
                    },
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Tab content ──────────────────────────────────────────
                        ...[
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
                const Icon(Icons.arrow_back_rounded,
                    color: AppProfileColors.teal, size: 20),
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
          // A search box that searched nothing used to fill the rest of
          // this bar; finding a patient happens on the Patients page.
        ],
      ),
    );
  }

  // ── Profile tabs ─────────────────────────────────────────────────────────────
  /// The design's tabs: the active one dark teal and bold, with a thick
  /// rounded bar under it, all over a thin line across the panel.
  Widget _buildProfileTabs() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(height: 2, color: _tabLine),
        Row(
          children: List.generate(_profileTabs.length, (i) {
            final active = i == _tabIndex;
            return InkWell(
              onTap: () => setState(() => _tabIndex = i),
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _profileTabs[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? _darkTeal : _tabIdle,
                          ),
                        ),
                      ),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: active ? _darkTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

const _panelBg = Color(0xFFE3F5F6);
const _darkTeal = Color(0xFF2E9FA5);
const _tabIdle = Color(0xFF8A8A8A);
const _tabLine = Color(0xFFCFE3E5);

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

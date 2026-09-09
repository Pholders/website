import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart';

/// PatientDetailPage — displays the detailed profile of a patient.
class PatientDetailPage extends StatelessWidget {
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    // Mock patient data for demonstration
    final mockPatient = Patient(
      id: patientId,
      name: 'Maria Wilson',
      condition: 'Acne Treatment',
      lastActivity: '2 hours ago',
      status: PatientStatus.stable,
      priority: 'Low',
      category: PatientCategory.outpatient,
      avatarInitials: 'MW',
    );

    return Scaffold(
      body: PatientProfileScreen(
        patient: mockPatient,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}

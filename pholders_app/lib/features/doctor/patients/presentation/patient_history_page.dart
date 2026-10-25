import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';

/// PatientHistoryPage — displays the medical history for a patient.
class PatientHistoryPage extends StatelessWidget {

  const PatientHistoryPage({super.key, required this.patientId});
  final String patientId;

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
      body: MedicalHistoryScreen(patient: mockPatient),
    );
  }
}

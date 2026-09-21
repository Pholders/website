import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';

/// PatientPrescriptionsPage — displays the prescriptions for a patient.
class PatientPrescriptionsPage extends StatelessWidget {

  const PatientPrescriptionsPage({super.key, required this.patientId});
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
      body: PrescriptionsScreen(patient: mockPatient),
    );
  }
}

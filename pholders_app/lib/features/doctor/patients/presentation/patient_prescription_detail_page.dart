import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';

/// PatientPrescriptionDetailPage — displays the detailed information of a prescription for a patient.
class PatientPrescriptionDetailPage extends StatelessWidget {

  const PatientPrescriptionDetailPage({super.key, required this.patientId, required this.prescriptionId});
  final String patientId;
  final String prescriptionId;

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
      body: Center(
        child: Text('Prescription Detail for ${mockPatient.name}'),
      ),
    );
  }
}

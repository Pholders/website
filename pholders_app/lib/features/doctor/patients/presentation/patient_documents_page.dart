import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';

/// PatientDocumentsPage — displays the documents for a patient.
class PatientDocumentsPage extends StatelessWidget {
  final String patientId;

  const PatientDocumentsPage({super.key, required this.patientId});

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
      body: DocumentsScreen(patient: mockPatient),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';

/// PatientAppointmentsPage — displays the appointments for a patient.
class PatientAppointmentsPage extends StatelessWidget {
  final String patientId;

  const PatientAppointmentsPage({super.key, required this.patientId});

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
      body: AppointmentsScreen(patient: mockPatient),
    );
  }
}
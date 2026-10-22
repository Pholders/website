import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medical_history_screen.dart';

/// PatientHistoryPage — displays the medical history for a patient.
///
/// The patient comes from the id in the address, resolved against the
/// doctor's own list. It used to be a fixed, invented record.
class PatientHistoryPage extends StatelessWidget {

  const PatientHistoryPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientScope(
        patientId: patientId,
        builder: (context, patient) => MedicalHistoryScreen(patient: patient),
      ),
    );
  }
}

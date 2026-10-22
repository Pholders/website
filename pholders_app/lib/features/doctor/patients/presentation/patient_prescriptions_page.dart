import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';

/// PatientPrescriptionsPage — displays the prescriptions for a patient.
///
/// The patient comes from the id in the address, resolved against the
/// doctor's own list. It used to be a fixed, invented record.
class PatientPrescriptionsPage extends StatelessWidget {

  const PatientPrescriptionsPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientScope(
        patientId: patientId,
        builder: (context, patient) => PrescriptionsScreen(patient: patient),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';
import 'package:pholders_app/features/doctor/patients/presentation/documents_screen.dart';

/// PatientDocumentsPage — displays the documents for a patient.
///
/// The patient comes from the id in the address, resolved against the
/// doctor's own list. It used to be a fixed, invented record.
class PatientDocumentsPage extends StatelessWidget {

  const PatientDocumentsPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientScope(
        patientId: patientId,
        builder: (context, patient) => DocumentsScreen(patient: patient),
      ),
    );
  }
}

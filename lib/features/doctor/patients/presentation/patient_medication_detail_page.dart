import 'package:flutter/material.dart';

/// PatientMedicationDetailPage — placeholder until Figma design is implemented.
class PatientMedicationDetailPage extends StatelessWidget {

  const PatientMedicationDetailPage({super.key, required this.patientId, required this.medicationId});
  final String patientId;
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PatientMedicationDetailPage')),
    );
  }
}

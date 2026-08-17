import 'package:flutter/material.dart';

/// PatientMedicationDetailPage — placeholder until Figma design is implemented.
class PatientMedicationDetailPage extends StatelessWidget {
  final String patientId;
  final String medicationId;

  const PatientMedicationDetailPage({super.key, required this.patientId, required this.medicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('PatientMedicationDetailPage')),
    );
  }
}

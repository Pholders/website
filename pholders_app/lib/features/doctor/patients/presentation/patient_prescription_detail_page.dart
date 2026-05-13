import 'package:flutter/material.dart';

/// PatientPrescriptionDetailPage — placeholder until Figma design is implemented.
class PatientPrescriptionDetailPage extends StatelessWidget {
  final String patientId;
  final String prescriptionId;

  const PatientPrescriptionDetailPage({super.key, required this.patientId, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('PatientPrescriptionDetailPage')),
    );
  }
}

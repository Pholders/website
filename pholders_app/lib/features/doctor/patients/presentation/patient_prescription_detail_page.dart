import 'package:flutter/material.dart';

/// PatientPrescriptionDetailPage — placeholder until Figma design is implemented.
class PatientPrescriptionDetailPage extends StatelessWidget {

  const PatientPrescriptionDetailPage({super.key, required this.patientId, required this.prescriptionId});
  final String patientId;
  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PatientPrescriptionDetailPage')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';

/// PatientPrescriptionDetailPage — one prescription, reached from a patient.
///
/// This route was never built: it printed a name and nothing else, and the
/// name belonged to an invented patient rather than to the id in the address.
///
/// A doctor's prescriptions are real and already have a detail view, reached
/// from the Prescriptions page, so this says where to find it rather than
/// standing in for it.
class PatientPrescriptionDetailPage extends StatelessWidget {

  const PatientPrescriptionDetailPage({
    super.key,
    required this.patientId,
    required this.prescriptionId,
  });
  final String patientId;
  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PatientPageNotice(
        icon: Icons.description_outlined,
        title: 'Open this from Prescriptions',
        detail: 'Prescriptions are listed on the Prescriptions page, where '
            'each one opens with its medicines, its signature and the '
            'pharmacy that dispensed it.',
      ),
    );
  }
}

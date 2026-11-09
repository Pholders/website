import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';

/// PatientMedicationDetailPage — a single medication on a patient's record.
///
/// Not built. The SRS puts doctor-side charting and medication tracking out
/// of scope, in "Provider-Side / Clinical Workflow Features (EHR Territory)",
/// and patient records readable by a doctor are a later phase.
///
/// This page used to show an invented medication with an invented adherence
/// figure for whichever id was in the address, which reads as a real clinical
/// record rather than as nothing.
class PatientMedicationDetailPage extends StatelessWidget {
  const PatientMedicationDetailPage({
    super.key,
    required this.patientId,
    required this.medicationId,
  });
  final String patientId;
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PatientPageNotice(
        icon: Icons.medication_outlined,
        title: 'Not part of this phase',
        detail: 'Tracking what a patient takes, and how reliably, belongs to '
            'the patient record rather than to the prescriber. This phase '
            'covers writing and signing a prescription, which is on the '
            'Prescriptions page.',
      ),
    );
  }
}

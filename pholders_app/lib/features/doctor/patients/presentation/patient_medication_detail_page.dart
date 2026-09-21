import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medication_details_screen.dart';

/// PatientMedicationDetailPage — displays the detailed information of a medication for a patient.
class PatientMedicationDetailPage extends StatelessWidget {

  const PatientMedicationDetailPage({super.key, required this.patientId, required this.medicationId});
  final String patientId;
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    // Mock medication data for demonstration
    const mockMedication = MedHistoryItem(
      medication: 'Isotretinoin',
      dosage: '20mg',
      frequency: 'Once Daily',
      duration: '30 days',
      isActive: true,
      adherence: 85,
    );

    return Scaffold(
      body: MedicationDetailsScreen(
        item: mockMedication,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}

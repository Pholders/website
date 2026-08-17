import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';

/// PatientListPage — displays the list of patients.
class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientsScreen(
        onPatientTap: (patient) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(
                patient: patient,
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
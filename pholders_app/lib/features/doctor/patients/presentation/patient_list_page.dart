import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart';

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
              // A pushed route has no Scaffold above it, so it needs its own:
              // without one the page has no background or Material for its
              // text fields. PatientDetailPage does the same.
              builder: (context) => Scaffold(
                body: PatientProfileScreen(
                  // The detail screens still type against the older shape, so
                  // the real record is converted at this one boundary.
                  patient: Patient.fromDoctorPatient(patient),
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';

/// PatientDetailPage — displays the detailed profile of a patient.
///
/// The patient comes from the id in the address, resolved against the
/// doctor's own list. It used to be a fixed, invented record.
class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientScope(
        patientId: patientId,
        builder: (context, patient) => PatientProfileScreen(
          patient: patient,
          // Reached by its address there is nothing underneath to pop back
          // to, and popping crashed; go to the patient list instead.
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.doctorPatients),
        ),
      ),
    );
  }
}

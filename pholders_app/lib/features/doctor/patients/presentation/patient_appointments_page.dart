import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_scope.dart';
import 'package:pholders_app/features/doctor/appointments/presentation/appointments_screen.dart';

/// PatientAppointmentsPage — displays the appointments for a patient.
///
/// The patient comes from the id in the address, resolved against the
/// doctor's own list. It used to be a fixed, invented record.
class PatientAppointmentsPage extends StatelessWidget {

  const PatientAppointmentsPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatientScope(
        patientId: patientId,
        builder: (context, patient) => AppointmentsScreen(patient: patient),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/shared/widgets/page_notice.dart';

/// Writing a prescription happens in a dialog on the Prescriptions page,
/// because it has to be attached to one of the doctor's own consultations
/// and that is chosen from the list. This route was never built, and said
/// only "To be implemented", which reads as the feature being missing when
/// it is the most finished part of the app.
class NewPrescriptionPage extends StatelessWidget {
  const NewPrescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageNotice(
      icon: Icons.edit_note_outlined,
      title: 'Prescriptions are written from the list',
      detail: 'Open Prescriptions and choose New Prescription. A prescription has to be attached to a consultation you have completed, and that is picked there.',
        goToLabel: 'Go to Prescriptions',
        goTo: AppRoutes.doctorPrescriptions,
    );
  }
}

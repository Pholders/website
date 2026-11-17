import 'package:flutter/material.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/shared/widgets/page_notice.dart';

/// A prescription opens inside the Prescriptions page rather than on a route
/// of its own, so this address was never built: it rendered the words
/// "PrescriptionDetailPage" and nothing else.
///
/// It stays reachable, because a deep link to it is a reasonable thing to
/// try, and now it says where the prescription actually is.
class PrescriptionDetailPage extends StatelessWidget {

  const PrescriptionDetailPage({super.key, required this.prescriptionId});
  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    return const PageNotice(
      icon: Icons.description_outlined,
      title: 'Prescriptions open from the list',
      detail: 'Open Prescriptions and click the prescription you want. It '
          'shows the medicines, the signature, and the pharmacy that '
          'dispensed it, and you can print or download it from there.',
      goToLabel: 'Go to Prescriptions',
      goTo: AppRoutes.doctorPrescriptions,
    );
  }
}

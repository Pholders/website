import 'package:flutter/material.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/shared/widgets/page_notice.dart';

/// Previewing was folded into the signing step: the dialog shows what is
/// about to be signed, and afterwards the real PDF can be printed.
class PreviewPrescriptionPage extends StatelessWidget {
  const PreviewPrescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageNotice(
      icon: Icons.preview_outlined,
      title: 'Preview happens when you sign',
      detail: 'The signing dialog shows the prescription before you commit to it, and once signed you can print or download the real document.',
        goToLabel: 'Go to Prescriptions',
        goTo: AppRoutes.doctorPrescriptions,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:pholders_app/shared/widgets/page_notice.dart';

/// Searching across prescriptions was never built. The doctor's own list is
/// filterable, which covers what this phase asks for.
class SearchScriptsPage extends StatelessWidget {
  const SearchScriptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageNotice(
      icon: Icons.search_outlined,
      title: 'Search your own prescriptions instead',
      detail: 'A search across every prescription is not part of this phase. Your own list can be filtered by status on the Prescriptions page.',
        goToLabel: 'Go to Prescriptions',
        goTo: AppRoutes.doctorPrescriptions,
    );
  }
}

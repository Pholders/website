import 'package:flutter/material.dart';
import 'package:pholders_app/shared/widgets/page_notice.dart';

/// Sick notes are a recorded requirement but not part of this phase, and
/// nothing behind them exists — there is no API for them at all. This is on
/// the sidebar, so a tester will click it, and a blank page would read as a
/// defect rather than as something deliberately left out.
class SickNotesPage extends StatelessWidget {
  const SickNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageNotice(
      icon: Icons.note_alt_outlined,
      title: 'Sick notes are not in this phase',
      detail: 'Issuing sick notes is on the list of things to build, but not for this release, so there is nothing behind this page yet. Nothing is broken.',
    );
  }
}

import 'package:flutter/material.dart';

import 'prescriptions_screen.dart';

/// The doctor's Prescriptions tab.
///
/// [PrescriptionsScreen] takes an optional patient; with none supplied it
/// lists every prescription the doctor has issued rather than one patient's.
class PrescriptionsListPage extends StatelessWidget {
  const PrescriptionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PrescriptionsScreen(),
    );
  }
}

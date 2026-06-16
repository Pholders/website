import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Fees Setup Settings page.
class DoctorFeesSettingsPage extends StatelessWidget {
  const DoctorFeesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'fees_setup',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Fees Setup — To be implemented')),
          ),
        ],
      ),
    );
  }
}

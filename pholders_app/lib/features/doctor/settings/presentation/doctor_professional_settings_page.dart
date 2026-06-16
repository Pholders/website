import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Professional Details Settings page.
class DoctorProfessionalSettingsPage extends StatelessWidget {
  const DoctorProfessionalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'professional',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Professional Details — To be implemented')),
          ),
        ],
      ),
    );
  }
}

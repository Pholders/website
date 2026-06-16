import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Security Settings page.
class DoctorSecuritySettingsPage extends StatelessWidget {
  const DoctorSecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'security_settings',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Security Settings — To be implemented')),
          ),
        ],
      ),
    );
  }
}

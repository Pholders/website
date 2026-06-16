import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Notifications Settings page.
class DoctorNotificationsSettingsPage extends StatelessWidget {
  const DoctorNotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'notifications',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Notifications Settings — To be implemented')),
          ),
        ],
      ),
    );
  }
}

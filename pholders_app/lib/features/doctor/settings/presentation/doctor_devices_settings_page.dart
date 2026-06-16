import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Device Management Settings page.
class DoctorDevicesSettingsPage extends StatelessWidget {
  const DoctorDevicesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'device_management',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Device Management — To be implemented')),
          ),
        ],
      ),
    );
  }
}

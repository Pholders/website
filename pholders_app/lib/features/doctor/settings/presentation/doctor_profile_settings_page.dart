import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Profile Settings page.
class DoctorProfileSettingsPage extends StatelessWidget {
  const DoctorProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'profile',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Doctor Profile Settings — To be implemented')),
          ),
        ],
      ),
    );
  }
}

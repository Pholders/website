import 'package:flutter/material.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Doctor Login Activity Settings page.
class DoctorLoginActivityPage extends StatelessWidget {
  const DoctorLoginActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        children: [
          SettingsSidebar(
            selectedItemId: 'login_activity',
            onMenuItemSelected: (_) {},
          ),
          const Expanded(
            child: Center(child: Text('Login Activity — To be implemented')),
          ),
        ],
      ),
    );
  }
}

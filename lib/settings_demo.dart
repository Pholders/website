import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/settings/presentation/settings_page.dart';
import 'package:pholders_app/shared/widgets/app_sidebar.dart';
import 'package:pholders_app/shared/widgets/app_top_navbar.dart';

/// Demo page to show settings directly without full app navigation
class SettingsDemo extends StatelessWidget {
  const SettingsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppTopNavbar(
          role: 'doctor',
          onMenuTap: () {},
        ),
      ),
      body: Row(
        children: [
          AppSidebar(
            role: 'doctor',
            collapsed: false, 
            onItemSelected: (dynamic _) {},
          ),
          const Expanded(
            child: SettingsPage(),
          ),
        ],
      ),
    );
  }
}

class InvalidType {
}

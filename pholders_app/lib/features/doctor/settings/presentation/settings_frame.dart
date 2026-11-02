import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Where each item in the settings sidebar goes.
void navigateDoctorSettings(BuildContext context, String id) {
  switch (id) {
    case 'personal_information':
      context.go(AppRoutes.doctorSettingsProfile);
    case 'professional':
      context.go(AppRoutes.doctorSettingsProfessional);
    case 'fees_setup':
      context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
    case 'notification_settings':
      context.go('${AppRoutes.doctorSettingsPractice}?tab=1');
    case 'notification_center':
      context.go(AppRoutes.doctorNotifications);
    case 'security_settings':
      context.go(AppRoutes.doctorSettingsSecurity);
    case 'device_management':
      context.go(AppRoutes.doctorSettingsDevices);
    case 'login_activity':
      context.go(AppRoutes.doctorSettingsLoginActivity);
    case 'preferences_settings':
      context.go(AppRoutes.doctorSettingsPreferences);
    case 'linked_services':
      context.go(AppRoutes.doctorSettingsLinkedServices);
    case 'help_center':
      context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=0');
    case 'privacy_policy':
      context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=1');
    case 'terms_of_service':
      context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=2');
    case 'contact_support':
      context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=3');
  }
}

/// The sidebar and card every settings screen sits in.
class DoctorSettingsFrame extends StatelessWidget {
  const DoctorSettingsFrame({
    super.key,
    required this.selectedItemId,
    required this.title,
    required this.children,
  });

  final String selectedItemId;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(
            selectedItemId: selectedItemId,
            onMenuItemSelected: (id) => navigateDoctorSettings(context, id),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(title: title, children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey explanatory text used across the settings screens.
const settingsNote = TextStyle(fontSize: 12, color: Color(0xFF748486), height: 1.4);

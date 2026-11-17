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
    return DoctorSettingsLayout(
      selectedItemId: selectedItemId,
      child: doctorSettingsCard(context, title: title, children: children),
    );
  }
}

/// A settings screen's content as it sits in [DoctorSettingsLayout]: the
/// round back arrow and title over a rule, then [children], scrolling.
///
/// No pencil in the header: it was a picture of an edit button that did
/// nothing. The back arrow returns to the settings home.
Widget doctorSettingsCard(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return SettingsContentCard(
    title: title,
    framed: false,
    showEdit: false,
    padding: const EdgeInsets.fromLTRB(26, 22, 28, 26),
    onBack: () => context.go(AppRoutes.doctorSettings),
    children: children,
  );
}

/// The doctor's settings frame, as in the design: on the white page, the
/// pale rounded panel titled "Settings", holding one white card on an aqua
/// edge. The menu is down the card's left and [child] fills the rest.
class DoctorSettingsLayout extends StatelessWidget {
  const DoctorSettingsLayout({
    super.key,
    required this.selectedItemId,
    required this.child,
  });

  final String selectedItemId;

  /// The page's content. It is given a bounded height and should scroll
  /// itself, as [SettingsContentCard] does.
  final Widget child;

  static const _panelBg = Color(0xFFE3F5F6);
  static const _aqua = Color(0xFF6DD0D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(31, 0, 38, 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          decoration: BoxDecoration(
            color: _panelBg,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(fontSize: 30, color: Colors.black)),
              const SizedBox(height: 20),
              Expanded(
                // The aqua shows down the left and along the bottom.
                child: Container(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: _aqua,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 230,
                            child: SettingsSidebar(
                              embedded: true,
                              selectedItemId: selectedItemId,
                              onMenuItemSelected: (id) =>
                                  navigateDoctorSettings(context, id),
                            ),
                          ),
                          const VerticalDivider(
                              width: 1, thickness: 1, color: Color(0xFFDDEBEC)),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small grey explanatory text used across the settings screens.
const settingsNote = TextStyle(fontSize: 12, color: Color(0xFF748486), height: 1.4);

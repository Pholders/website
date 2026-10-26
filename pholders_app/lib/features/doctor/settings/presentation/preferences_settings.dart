// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

import '../../../../shared/widgets/settings_not_saved_banner.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class PreferencesSettings extends StatelessWidget {
  const PreferencesSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'preferences_settings',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Notifications',
                children: const [
                  SettingsNotSavedBanner(
                    'Nothing here is saved yet. There are no notification '
                    'settings on the server for a doctor, so these switches '
                    'have nowhere to write to and are switched off.',
                  ),
                  _Section(
                    title: 'Channels',
                    children: [
                      _SwitchLine('Push Notifications'),
                      _SwitchLine('Email Notifications'),
                      _SwitchLine('SMS Notifications'),
                    ],
                  ),
                  _DividerGap(),
                  _Section(
                    title: 'Quiet Hours',
                    children: [
                      _CheckLine('Enable Quiet Hours', switchAtEnd: true),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text('Start:10:00 PM',
                                    style: TextStyle(fontSize: 13))),
                            Expanded(
                                child: Text('End: 07:00 AM',
                                    style: TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _DividerGap(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text('Frequency', style: TextStyle(fontSize: 13))),
                        SettingsInput(
                          text: 'Instant',
                          width: 92,
                          height: 22,
                          trailing: Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Color(0xFF748486)),
                        ),
                      ],
                    ),
                  ),
                  _DividerGap(),
                  _Section(
                    title: 'Advanced',
                    children: [
                      _CheckLine('Urgent alert override quiet hours'),
                      SizedBox(height: 12),
                      _CheckLine('Hide sensitive content'),
                    ],
                  ),
                  SizedBox(height: 18),
                  _Section(
                    title: 'Advanced',
                    children: [
                      _SwitchLine('Urgent alert override quiet hours'),
                      _SwitchLine('Hide sensitive content'),
                    ],
                  ),
                  SizedBox(height: 6),
                  SettingsFullWidthAction('Save Changes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'profile':
        context.go(AppRoutes.doctorSettingsProfile);
        break;
      case 'professional':
        context.go(AppRoutes.doctorSettingsProfessional);
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPractice);
        break;
      case 'notification_settings':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=1');
        break;
      case 'notification_center':
        context.go(AppRoutes.doctorNotifications);
        break;
      case 'security_settings':
        context.go(AppRoutes.doctorSettingsSecurity);
        break;
      case 'device_management':
        context.go(AppRoutes.doctorSettingsDevices);
        break;
      case 'login_activity':
        context.go(AppRoutes.doctorSettingsLoginActivity);
        break;
      case 'preferences_settings':
        context.go(AppRoutes.doctorSettingsPreferences);
        break;
      case 'linked_services':
        context.go(AppRoutes.doctorSettingsLinkedServices);
        break;
      case 'help_center':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=0');
        break;
      case 'privacy_policy':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=1');
        break;
      case 'terms_of_service':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=2');
        break;
      case 'contact_support':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=3');
        break;
                        default:
        break;
    }
  }

}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const TinySwitch(),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.label, {this.switchAtEnd = false});

  final String label;
  final bool switchAtEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SmallCheck(),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (switchAtEnd) const TinySwitch(),
      ],
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}

class _CheckSection extends StatelessWidget {
  const _CheckSection({required this.title, required this.labels});

  final String title;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          const SizedBox(height: 8),
          ...labels.map(
            (label) => _SmallCheckLabel(label, checked: true, large: true),
          ),
        ],
      ),
    );
  }
}

class _SmallCheckLabel extends StatelessWidget {
  const _SmallCheckLabel(
    this.label, {
    this.checked = false,
    this.large = false,
  });

  final String label;
  final bool checked;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SmallCheck(checked: checked),
        Text(label, style: TextStyle(fontSize: large ? 11 : 10)),
      ],
    );
  }
}



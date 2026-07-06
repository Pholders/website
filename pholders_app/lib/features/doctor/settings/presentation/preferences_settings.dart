// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
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
        Padding(
          padding: EdgeInsets.fromLTRB(28, 4, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle('Notification Preferences'),
              SizedBox(height: 10),
              _SwitchLine('Push Notifications'),
              _SwitchLine('Email Notifications'),
            ],
          ),
        ),
        _CompactDivider(),
        _CheckSection(
          title: 'Appointment Preferences',
          labels: [
            'New Appointment Booked',
            'Appointment Reminders',
            'Appointment Cancellations',
            'Missed Appointments',
          ],
        ),
        _CompactDivider(),
        _CheckSection(
          title: 'Patient Messages',
          labels: ['New Patient Messages', 'Message Replies'],
        ),
        _CompactDivider(),
        _CheckSection(
          title: 'General Notifications',
          labels: [
            'Lab Result Updates',
            'Prescription Renewal Alerts',
            'Announcements & News',
          ],
        ),
        _CompactDivider(),
        Padding(
          padding: EdgeInsets.fromLTRB(28, 4, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle('Sound & Vibration'),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notification Sound',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  SettingsInput(
                    text: 'Select Sound',
                    width: 150,
                    height: 14,
                    trailing: Icon(Icons.keyboard_arrow_down, size: 14),
                  ),
                ],
              ),
              SizedBox(height: 9),
              _SwitchLine('Vibrate on Notification'),
            ],
          ),
        ),
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
        context.go(AppRoutes.doctorSettingsFees);
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPractice);
        break;
      case 'notification_settings':
        context.go(AppRoutes.doctorSettingsPractice + '?tab=1');
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

class _SwitchLine extends StatelessWidget {
  const _SwitchLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          const TinySwitch(),
        ],
      ),
    );
  }
}

class _CompactDivider extends StatelessWidget {
  const _CompactDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}
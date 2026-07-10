
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class PracticeSettings extends StatelessWidget {
  const PracticeSettings({super.key, this.initialTab = 0});

  final int initialTab;

    @override
    Widget build(BuildContext context) {
      return initialTab == 1
          ? _PracticeNotifications(_navigate)
          : _FeesSetup(_navigate);
    }

    void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go('${AppRoutes.doctorSettings}account?tab=0');
        break;
      case 'professional':
        context.go('${AppRoutes.doctorSettings}account?tab=1');
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
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

class _FeesSetup extends StatelessWidget {
  const _FeesSetup(this._navigate);

  final Function(BuildContext, String) _navigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'fees_setup',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
                    // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Fees Setup',
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 32, bottom: 12),
                    child: Text(
                      'Set and manage your service pricing',
                      style: TextStyle(fontSize: 16, color: Color(0xFFC1C1C1)),
                    ),
                  ),
                  const _CompactDivider(),
                  const _FeeSection(
                    title: 'Consultation Fees',
                    rows: [
                      ('In-person Fee:', 'R', '0.00'),
                      ('Video Fee:', 'R', '0.00'),
                      ('Phone Fee:', 'R', '0.00'),
                    ],
                  ),
                  const _CompactDivider(),
                  const _FeeSection(
                    title: 'Time-based pricing',
                    prefix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TinySwitch(),
                        SizedBox(width: 10),
                        Text('Enable time-based pricing', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    rows: [
                      ('15 min:', 'R', '0.00'),
                      ('30 min:', 'R', '0.00'),
                      ('60 min:', 'R', '0.00'),
                    ],
                  ),
                  const _CompactDivider(),
                  const _FeeSection(
                    title: 'Special Fees',
                    rows: [
                      ('Follow-up Fee:', 'R', '0.00'),
                      ('After-Hours Fee:', 'R', '0.00'),
                    ],
                  ),
                  const _CompactDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsSectionTitle('Insurance settings'),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            TinySwitch(),
                            SizedBox(width: 10),
                            Text('Accept Medical Aid', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: const [
                            _SmallCheckLabel('Discovery Health', checked: true),
                            _SmallCheckLabel('Bonitas'),
                            _SmallCheckLabel('Momentum Medical'),
                            _SmallCheckLabel('Medihelp'),
                            _SmallCheckLabel('Fedhealth'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const _FeeLine(
                            label: 'Cash Rate:', currency: 'R', amount: '0.00'),
                      ],
                    ),
                  ),
                  const _CompactDivider(),
                                    const Padding(
                    padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionTitle('Cancellation Policy'),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Cancellation:', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 12),
                            SettingsInput(
                                text: 'Free cancellation', width: 175, height: 16),
                          ],
                        ),
                        SizedBox(height: 8),
                        _FeeLine(label: 'Late Fee:', currency: 'R', amount: '0.00'),
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
}

class _PracticeNotifications extends StatelessWidget {
  const _PracticeNotifications(this._navigate);

  final Function(BuildContext, String) _navigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'notification_settings',
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
                      labels: ['New Patient Messages', 'Message Replies']),
                  _CompactDivider(),
                  _CheckSection(
                    title: 'General Notifications',
                    labels: [
                      'Lab Result Updates',
                      'Prescription Renewal Alerts',
                      'Announcements & News'
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
                                child: Text('Notification Sound',
                                    style: TextStyle(fontSize: 11))),
                            SettingsInput(
                                text: 'Select Sound',
                                width: 150,
                                height: 14,
                                trailing: Icon(Icons.keyboard_arrow_down, size: 14)),
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
}

class _FeeSection extends StatelessWidget {
  const _FeeSection({required this.title, required this.rows, this.prefix});

  final String title;
  final List<(String, String, String)> rows;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          if (prefix != null) ...[
            const SizedBox(height: 8),
            prefix!,
          ],
          const SizedBox(height: 8),
          ...rows.map((row) =>
              _FeeLine(label: row.$1, currency: row.$2, amount: row.$3)),
        ],
      ),
    );
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine(
      {required this.label, required this.currency, required this.amount});

  final String label;
  final String currency;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 11))),
          Container(
            height: 14,
            width: 56,
            decoration: BoxDecoration(
                color: const Color(0xFFD2D2D2),
                borderRadius: BorderRadius.circular(3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currency, style: const TextStyle(fontSize: 9)),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 10,
                  alignment: Alignment.center,
                  color: const Color(0xFF9F9F9F),
                  child: Text(amount,
                      style: const TextStyle(fontSize: 9, color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
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
              (label) => _SmallCheckLabel(label, checked: true, large: true)),
        ],
      ),
    );
  }
}

class _SmallCheckLabel extends StatelessWidget {
  const _SmallCheckLabel(this.label,
      {this.checked = false, this.large = false});

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
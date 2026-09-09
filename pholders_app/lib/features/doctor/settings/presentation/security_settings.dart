// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/doctor_auth_repository.dart';
import '../../../auth/data/models/doctor_activity.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    switch (initialTab) {
      case 1:
        return const _DeviceManagement();
      case 2:
        return const _LoginActivity();
      default:
        return const _SecuritySettings();
    }
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

class _SecuritySettings extends StatelessWidget {
  const _SecuritySettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'security_settings',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Security Settings',
                children: const [
        _Section(
          title: 'Password & Authentication',
          children: [
            _SwitchLine('Change Password'),
            _SwitchLine('Biometric Login'),
            _SwitchLine('Two-Factor Authentication'),
          ],
        ),
        _DividerGap(),
        _Section(
          title: 'Account Protection',
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Auto Logout Timer',
                        style: TextStyle(fontSize: 11))),
                SettingsInput(
                    width: 120,
                    height: 12,
                    trailing: Icon(Icons.keyboard_arrow_down, size: 13)),
              ],
            ),
            SizedBox(height: 16),
            SettingsFullWidthAction('Log out of all devices'),
          ],
        ),
        _DividerGap(),
                _Section(
          title: 'Security Alerts',
          children: [
            _SwitchLine('Login Alerts'),
            _SwitchLine('Suspicious Activity Alerts'),
            _ChevronLine('Device Management'),
            _ChevronLine('Login Activity'),
          ],
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
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
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

class _DeviceManagement extends StatefulWidget {
  const _DeviceManagement();

  @override
  State<_DeviceManagement> createState() => _DeviceManagementState();
}

class _DeviceManagementState extends State<_DeviceManagement> {
  // Read-only, so it reads the repository directly rather than adding a store
  // slice nothing else would use.
  late Future<List<ActiveSession>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = sl<DoctorAuthRepository>().fetchSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'device_management',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Device Management',
                children: [
        FutureBuilder<List<ActiveSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final e = snapshot.error;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  e is ApiException
                      ? e.message
                      : 'Could not load your signed-in devices.',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final sessions = snapshot.data ?? const <ActiveSession>[];
            if (sessions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No active sessions.'),
              );
            }

            // The backend returns them most recently active first, so the
            // first row is this device.
            final current = sessions.first;
            final others = sessions.skip(1).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsSectionTitle('Current Device'),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 32, color: Colors.black),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.device,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 18),
                        Text(current.ipAddress ?? 'Unknown location',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Active Now',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsDivider(),
                const SizedBox(height: 12),
                SettingsSectionTitle('Other Devices (${others.length})'),
                const SizedBox(height: 10),
                if (others.isEmpty)
                  const Text('No other devices are signed in.')
                else
                  for (final session in others) ...[
                    _DeviceRow(
                      icon: Icons.laptop_mac,
                      name: '${session.device} - '
                          '${session.ipAddress ?? 'unknown'}',
                    ),
                    const SettingsDivider(),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
                const SizedBox(height: 14),
        const SettingsFullWidthAction('Log out of all devices'),
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

class _LoginActivity extends StatelessWidget {
  const _LoginActivity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'login_activity',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Login Activity',
                children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('April 13, 10:30', style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              _ActivityLine(
                  icon: Icons.location_pin,
                  iconColor: Color(0xFFD93A36),
                  label: 'Johannesburg'),
              _ActivityLine(
                  icon: Icons.phone_android, label: 'Chrome - Windows'),
              _ActivityLine(
                  icon: Icons.check_circle,
                  iconColor: Color(0xFF45C7C4),
                  label: 'Successful'),
            ],
          ),
        ),
        const SettingsDivider(),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('April 12, 22:10', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 14),
              const _ActivityLine(
                  icon: Icons.warning,
                  iconColor: Color(0xFFFFB000),
                  label: 'Unknown Location'),
              const _ActivityLine(
                  icon: Icons.cancel,
                  iconColor: Color(0xFFFF443A),
                  label: 'Failed Login'),
              const SizedBox(height: 10),
              Container(
                width: 540,
                padding: const EdgeInsets.fromLTRB(32, 22, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Color(0xFFFFB000), size: 22),
                        SizedBox(width: 18),
                        Text('Suspicious Activity!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('This login was from a new location.',
                        style: TextStyle(fontSize: 13)),
                    SettingsDivider(),
                    SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 250,
                        child: SettingsFullWidthAction('Secure Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SettingsDivider(),
                const SizedBox(height: 14),
        const SettingsFullWidthAction('Report Suspicious Activity'),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          const TinySwitch(),
        ],
      ),
    );
  }
}

class _ChevronLine extends StatelessWidget {
  const _ChevronLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF8E8E8E)),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.icon, required this.name});

  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.black),
        const SizedBox(width: 16),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
        Container(
          width: 105,
          height: 28,
          decoration: BoxDecoration(
            color: SettingsShell.panelMint,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFCFECEE)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Log Out', style: TextStyle(fontSize: 14)),
              SizedBox(width: 12),
              Icon(Icons.chevron_right, size: 16, color: Color(0xFF8E8E8E)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({
    required this.icon,
    required this.label,
    this.iconColor = Colors.black,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class SupportLegalSettings extends StatelessWidget {
  const SupportLegalSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    switch (initialTab) {
      case 1:
        return const _LegalPanel(
          title: 'Privacy Policy',
          body: [
            'Data Collection',
            'Patient information is handled with care and used only for healthcare workflows.',
            'Data Security',
            'All account, practice, and communication data stays protected by your security preferences.',
          ],
        );
      case 2:
        return const _LegalPanel(
          title: 'Terms of Service',
          body: [
            'Account Responsibilities',
            'Doctors are responsible for keeping credentials, fees, and practice details accurate.',
            'Service Usage',
            'PHolders tools are provided for patient care, scheduling, prescriptions, and secure communication.',
          ],
        );
      case 3:
        return const _ContactSupport();
      default:
        return const _HelpCenter();
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

class _HelpCenter extends StatelessWidget {
  const _HelpCenter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'help_center',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Help Center',
                children: [
        _HelpSearch(),
        SizedBox(height: 18),
        _HelpRow(
            icon: Icons.person_outline,
            title: 'Account & profile',
            text: 'Manage your profile and professional details'),
        _HelpRow(
            icon: Icons.lock_outline,
            title: 'Security',
            text: 'Password, devices, login activity and alerts'),
        _HelpRow(
            icon: Icons.link,
            title: 'Linked services',
            text: 'Medical aid, calendar, payments and messages'),
                SizedBox(height: 20),
        SettingsFullWidthAction('Open Help Center'),
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

class _LegalPanel extends StatelessWidget {
  const _LegalPanel({required this.title, required this.body});

  final String title;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'privacy_policy',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: title,
                children: [
                  for (var index = 0; index < body.length; index += 2) ...[
                    SettingsSectionTitle(body[index]),
                    const SizedBox(height: 8),
                    Text(
                      body[index + 1],
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B4B4B), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    if (index + 2 < body.length) const SettingsDivider(),
                    if (index + 2 < body.length) const SizedBox(height: 18),
                  ],
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

class _ContactSupport extends StatelessWidget {
  const _ContactSupport();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'contact_support',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Contact Support',
                children: [
        Row(
          children: [
            Expanded(child: _SupportField(label: 'First Name')),
            SizedBox(width: 24),
            Expanded(child: _SupportField(label: 'Last Name')),
          ],
        ),
        SizedBox(height: 20),
        _SupportField(label: 'Email Address'),
        SizedBox(height: 20),
        _SupportField(label: 'Subject'),
        SizedBox(height: 20),
        _SupportField(label: 'Message', height: 120),
                SizedBox(height: 24),
        SettingsFullWidthAction('Send Message'),
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

class _HelpSearch extends StatelessWidget {
  const _HelpSearch();

  @override
  Widget build(BuildContext context) {
    return const SettingsInput(
      hint: 'Search help articles',
      icon: Icons.search,
      height: 34,
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleIconButton(icon: icon, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 12, color: SettingsShell.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E8E)),
        ],
      ),
    );
  }
}

class _SupportField extends StatelessWidget {
  const _SupportField({required this.label, this.height = 27});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        SettingsInput(height: height),
      ],
    );
  }
}

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class IntegrationsSettings extends StatelessWidget {
  const IntegrationsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'linked_services',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Linked Services',
                children: const [
        _IntegrationSection(
          title: 'Medical Aid',
          rows: [
            _IntegrationRow(
                icon: Icons.health_and_safety,
                color: Color(0xFFE94162),
                title: 'Discovery',
                subtitle: 'Last synced 2 hours ago',
                action: 'Disconnect'),
            _IntegrationRow(
                icon: Icons.shield,
                color: Color(0xFF77A5FF),
                title: 'Bonitas',
                action: 'Connect'),
            _IntegrationRow(
                icon: Icons.local_hospital,
                color: Color(0xFF3A9EA5),
                title: 'Momentum',
                action: 'Connect'),
          ],
        ),
        _ThinDivider(),
        _IntegrationSection(
          title: 'Calendar',
          rows: [
            _IntegrationRow(
                icon: Icons.calendar_month,
                color: Color(0xFF4285F4),
                title: 'Google Calendar',
                subtitle: 'Last synced 5 minutes ago',
                action: 'Connect'),
            _IntegrationRow(
                icon: Icons.email,
                color: Color(0xFF2D9CDB),
                title: 'Outlook Calendar',
                subtitle: 'Last synced 5 minutes ago',
                action: 'Disconnect'),
          ],
        ),
        _ThinDivider(),
        _IntegrationSection(
          title: 'Payments',
          rows: [
            _IntegrationRow(
                icon: Icons.payment,
                color: Color(0xFF1B73E8),
                title: 'PayPal',
                subtitle: 'Last synced 4 hours ago',
                action: 'Connect'),
          ],
        ),
        _ThinDivider(),
        _IntegrationSection(
          title: 'Communication',
          rows: [
            _IntegrationRow(
                icon: Icons.chat,
                color: Color(0xFF25D366),
                title: 'WhatsApp Notifications',
                action: 'Connect'),
          ],
        ),
                SizedBox(height: 18),
        SettingsFullWidthAction('Manage Integrations'),
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

class _IntegrationSection extends StatelessWidget {
  const _IntegrationSection({required this.title, required this.rows});

  final String title;
  final List<_IntegrationRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.action,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String action;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 9, color: Colors.black)),
              ],
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SettingsShell.panelMint,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCFECEE)),
            ),
            child: Text(action,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}

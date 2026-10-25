import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Pharmacy Settings page — hosts the SettingsSidebar and routes to sub-pages.
class PharmacySettingsPage extends StatelessWidget {
  const PharmacySettingsPage({super.key});

  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _bgLight = Color(0xFFE8F8F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'linked_services',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Welcome / landing content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildWelcomeCard(context),
            ),
          ),
        ],
      ),
    );
  }

    void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go(AppRoutes.pharmacySettingsPersonalInfo);
        break;
      case 'pharmacy_details':
        context.go(AppRoutes.pharmacySettingsPharmacyDetails);
        break;
      case 'professional':
        context.go(AppRoutes.pharmacySettingsProfessional);
        break;
      case 'notification_settings':
      case 'preferences_notifications':
        context.go(AppRoutes.pharmacySettingsNotifications);
        break;
      case 'notification_center':
        context.go(AppRoutes.pharmacySettingsNotificationCenter);
        break;
      case 'profile':
        context.go(AppRoutes.pharmacySettingsProfile);
        break;
      case 'linked_services':
        context.go(AppRoutes.pharmacySettingsLinkedServices);
        break;
      default:
        break;
    }
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: _tealBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a category from the sidebar to manage your settings.',
                        style: const TextStyle(fontSize: 14, color: _textMuted),
                      ),
                                            const SizedBox(height: 32),
                      _buildQuickLink(
                        context,
                        icon: Icons.notifications_active_outlined,
                        label: 'Notification Settings',
                        subtitle: 'Manage how script, order, and system alerts are delivered',
                        onTap: () => context.go(AppRoutes.pharmacySettingsNotifications),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickLink(
                        context,
                        icon: Icons.inbox_outlined,
                        label: 'Notification Centre',
                        subtitle: 'Review sent notifications and alert history',
                        onTap: () => context.go(AppRoutes.pharmacySettingsNotificationCenter),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickLink(
                        context,
                        icon: Icons.cable_outlined,
                        label: 'Linked Services',
                        subtitle: 'Connect medical aid, calendar, and payment integrations',
                        onTap: () => context.go(AppRoutes.pharmacySettingsLinkedServices),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _tealBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x33309CA3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: _teal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

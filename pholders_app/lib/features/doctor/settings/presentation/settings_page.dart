import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import 'settings_frame.dart';

/// The settings home: the settings frame with nothing chosen yet, and two
/// shortcuts.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _bgLight = Color(0xFFE8F8F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    // Nothing is chosen in the menu here. It used to show Linked Services
    // as the current page, which it is not.
    return DoctorSettingsLayout(
      selectedItemId: '',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a setting',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick a page from the menu on the left, or jump straight to one '
              'of these.',
              style: TextStyle(fontSize: 14, color: _textMuted),
            ),
            const SizedBox(height: 28),
            _buildQuickLink(
              context,
              icon: Icons.notifications_active_outlined,
              label: 'Notification Centre',
              subtitle: 'Review your notifications and alert history',
              onTap: () => context.go(AppRoutes.doctorNotifications),
            ),
            const SizedBox(height: 12),
            _buildQuickLink(
              context,
              icon: Icons.cable_outlined,
              label: 'Linked Services',
              subtitle:
                  'Connect medical aid, calendar, and payment integrations',
              onTap: () => context.go(AppRoutes.doctorSettingsLinkedServices),
            ),
          ],
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
              decoration: const BoxDecoration(
                color: Color(0x33309CA3),
                shape: BoxShape.circle,
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

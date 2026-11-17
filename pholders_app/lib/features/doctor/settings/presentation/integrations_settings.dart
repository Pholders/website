import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import 'settings_frame.dart';

/// Linked Services.
///
/// It listed Discovery "last synced 2 hours ago", Google and Outlook
/// calendars "last synced 5 minutes ago", PayPal and WhatsApp, with Connect
/// and Disconnect labels that did nothing, and had no settings sidebar.
/// Nothing can be linked yet, so it says so and points to where each of
/// those things is really handled.
class IntegrationsSettings extends StatelessWidget {
  const IntegrationsSettings({super.key});

  static const _instead = <(IconData, String, String, String?)>[
    (Icons.health_and_safety_outlined, 'Medical aid',
        'Choose the schemes you accept on Professional Details. Claims are not sent to schemes from Pholders yet.',
        AppRoutes.doctorSettingsProfessional),
    (Icons.payments_outlined, 'Payments',
        'Card payments go through Pholders, by Stripe. See what patients paid on Billing.',
        AppRoutes.doctorBilling),
    (Icons.calendar_month_outlined, 'Calendar',
        'Your bookings are on the Appointments page. Syncing with Google or Outlook is not available.',
        AppRoutes.doctorAppointments),
    (Icons.notifications_none, 'Messages and alerts',
        'You are told about bookings, cancellations, dispensed scripts and reviews in the portal. WhatsApp and SMS are not available.',
        AppRoutes.doctorNotifications),
  ];

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: 'linked_services',
      title: 'Linked Services',
      children: [
        const Text(
          'No outside services can be linked to your account yet. This is '
          'where each of these is handled instead.',
          style: settingsNote,
        ),
        const SizedBox(height: 16),
        for (final (icon, title, text, route) in _instead)
          InkWell(
            onTap: route == null ? null : () => context.go(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleIconButton(icon: icon, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(text, style: const TextStyle(fontSize: 12, color: SettingsShell.muted)),
                      ],
                    ),
                  ),
                  if (route != null)
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E8E)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

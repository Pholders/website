import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import 'settings_frame.dart';

/// Preferences Settings.
///
/// It was a second notifications page: push, email and SMS channels, quiet
/// hours fixed at 10 PM to 7 AM, a frequency box and two "Advanced" sections
/// with the same two options, all switched off with a banner saying nothing
/// was saved. The real notification choices are on Notification Settings,
/// so this points there rather than repeating them.
class PreferencesSettings extends StatelessWidget {
  const PreferencesSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: 'preferences_settings',
      title: 'Preferences',
      children: [
        const Text(
          'There are no other preferences to set yet. Which notifications '
          'you get is chosen on Notification Settings. Quiet hours, email '
          'and SMS are not available, as notifications show in the portal '
          'only.',
          style: settingsNote,
        ),
        const SizedBox(height: 16),
        SettingsButton(
          'Open Notification Settings',
          icon: Icons.notifications_none,
          width: 250,
          height: 34,
          onTap: () => context.go('${AppRoutes.doctorSettingsPractice}?tab=1'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../shared/widgets/settings_shell.dart';
import 'account_settings.dart';
import 'integrations_settings.dart';
import 'practice_settings.dart';
import 'preferences_settings.dart';
import 'security_settings.dart';
import 'support_legal_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedItemId = 'account/profile';

  static const List<SettingsMenuItem> _menuItems = [
    SettingsMenuItem(
      id: 'account',
      label: 'Account',
      iconPath: 'assets/icons/Account.png',
      subItems: [
        SettingsSubMenuItem(id: 'account/profile', label: 'Profile'),
        SettingsSubMenuItem(id: 'account/professional', label: 'Professional'),
      ],
    ),
    SettingsMenuItem(
      id: 'practice',
      label: 'Practice',
      iconPath: 'assets/icons/practice.png',
      subItems: [
        SettingsSubMenuItem(id: 'practice/fees_setup', label: 'Fees Setup'),
        SettingsSubMenuItem(
            id: 'practice/notifications', label: 'Notifications'),
      ],
    ),
    SettingsMenuItem(
      id: 'security',
      label: 'Security',
      iconPath: 'assets/icons/security.png',
      subItems: [
        SettingsSubMenuItem(
            id: 'security/security_settings', label: 'Security Settings'),
        SettingsSubMenuItem(
            id: 'security/device_management', label: 'Device Management'),
        SettingsSubMenuItem(
            id: 'security/login_activity', label: 'Login Activity'),
      ],
    ),
    SettingsMenuItem(
      id: 'preferences',
      label: 'Preferences',
      iconPath: 'assets/icons/preference.png',
      subItems: [
        SettingsSubMenuItem(
            id: 'preferences/notifications', label: 'Notifications'),
      ],
    ),
    SettingsMenuItem(
      id: 'integrations',
      label: 'Integrations',
      iconPath: 'assets/icons/integrations.png',
      subItems: [
        SettingsSubMenuItem(
            id: 'integrations/linked_services', label: 'Linked Services'),
      ],
    ),
    SettingsMenuItem(
      id: 'support_legal',
      label: 'Support & Legal',
      iconPath: 'assets/icons/support.png',
      subItems: [
        SettingsSubMenuItem(
            id: 'support_legal/help_center', label: 'Help Center'),
        SettingsSubMenuItem(
            id: 'support_legal/privacy_policy', label: 'Privacy Policy'),
        SettingsSubMenuItem(
            id: 'support_legal/terms_of_service', label: 'Terms of Service'),
        SettingsSubMenuItem(
            id: 'support_legal/contact_support', label: 'Contact Support'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final sidebar = _SettingsSidebar(
                    menuItems: _menuItems,
                    selectedItemId: _selectedItemId,
                    compact: compact,
                    onItemSelected: (id) =>
                        setState(() => _selectedItemId = id),
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: SettingsShell.pageMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 220, child: sidebar),
                              const SizedBox(height: 12),
                              Expanded(child: _buildContent()),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 230, child: sidebar),
                              Expanded(child: _buildContent()),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedItemId) {
      case 'account/profile':
        return const AccountSettings(initialTab: 0);
      case 'account/professional':
        return const AccountSettings(initialTab: 1);
      case 'practice/fees_setup':
        return const PracticeSettings(initialTab: 0);
      case 'practice/notifications':
        return const PracticeSettings(initialTab: 1);
      case 'security/security_settings':
        return const SecuritySettingsPage(initialTab: 0);
      case 'security/device_management':
        return const SecuritySettingsPage(initialTab: 1);
      case 'security/login_activity':
        return const SecuritySettingsPage(initialTab: 2);
      case 'preferences/notifications':
        return const PreferencesSettings();
      case 'integrations/linked_services':
        return const IntegrationsSettings();
      case 'support_legal/help_center':
        return const SupportLegalSettings(initialTab: 0);
      case 'support_legal/privacy_policy':
        return const SupportLegalSettings(initialTab: 1);
      case 'support_legal/terms_of_service':
        return const SupportLegalSettings(initialTab: 2);
      case 'support_legal/contact_support':
        return const SupportLegalSettings(initialTab: 3);
      default:
        return const AccountSettings(initialTab: 0);
    }
  }
}

class SettingsMenuItem {
  const SettingsMenuItem({
    required this.id,
    required this.label,
    required this.iconPath,
    required this.subItems,
  });

  final String id;
  final String label;
  final String iconPath;
  final List<SettingsSubMenuItem> subItems;
}

class SettingsSubMenuItem {
  const SettingsSubMenuItem({required this.id, required this.label});

  final String id;
  final String label;
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.menuItems,
    required this.selectedItemId,
    required this.onItemSelected,
    this.compact = false,
  });

  final List<SettingsMenuItem> menuItems;
  final String selectedItemId;
  final ValueChanged<String> onItemSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: compact ? const Radius.circular(18) : Radius.zero,
          bottomLeft: compact ? Radius.zero : const Radius.circular(18),
        ),
        border: const Border(left: BorderSide(color: SettingsShell.accent, width: 6)),
      ),
      padding: const EdgeInsets.fromLTRB(26, 18, 18, 16),
      child: ListView.separated(
        scrollDirection: compact ? Axis.horizontal : Axis.vertical,
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => SizedBox(width: compact ? 24 : 0, height: compact ? 0 : 14),
        itemBuilder: (context, index) => SizedBox(
          width: compact ? 190 : null,
          child: _buildItem(menuItems[index]),
        ),
      ),
    );
  }

  Widget _buildItem(SettingsMenuItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFE3FAFA),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                item.iconPath,
                width: 13,
                height: 13,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...item.subItems.map(
          (sub) {
            final selected = selectedItemId == sub.id;
            return InkWell(
              onTap: () => onItemSelected(sub.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: Text(
                  sub.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? const Color(0xFF12A2B0)
                        : const Color(0xFFC0C0C0),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

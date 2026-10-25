import 'package:flutter/material.dart';

import '../models/settings_menu_item.dart';

/// Settings sidebar used across all pages under the Settings section.
///
/// Displays a grouped menu with expandable sections (Account, Practice,
/// Security, Preferences, Integrations, Support & Legal). Highlights the
/// currently selected sub-item and notifies the parent via [onMenuItemSelected].
class SettingsSidebar extends StatefulWidget {
  const SettingsSidebar({
    super.key,
    required this.onMenuItemSelected,
    this.selectedItemId,
  });

  final Function(String) onMenuItemSelected;
  final String? selectedItemId;

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealLight = Color(0x33309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  late List<SettingsMenuItem> menuItems;
  String? expandedMenuId;
  String? selectedItemId;

  @override
  void initState() {
    super.initState();
    selectedItemId = widget.selectedItemId;
    _initializeMenuItems();
    // Auto-expand the section that contains the selected item
    if (selectedItemId != null) {
      for (final item in menuItems) {
        if (item.subItems?.any((s) => s.id == selectedItemId) ?? false) {
          expandedMenuId = item.id;
          break;
        }
      }
    }
  }

  @override
  void didUpdateWidget(SettingsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItemId != oldWidget.selectedItemId) {
      setState(() {
        selectedItemId = widget.selectedItemId;
      });
    }
  }

        void _initializeMenuItems() {
        menuItems = [
                const SettingsMenuItem(
            id: 'account',
            label: 'Account',
            icon: IconType.account,
            subItems: [
              const SettingsSubMenuItem(id: 'personal_information', label: 'Personal Information'),
              const SettingsSubMenuItem(id: 'professional', label: 'Professional Details'),
            ],
          ),
          const SettingsMenuItem(
            id: 'practice',
            label: 'Practice',
            icon: IconType.practice,
            subItems: [
              const SettingsSubMenuItem(id: 'fees_setup', label: 'Fees Setup'),
              const SettingsSubMenuItem(id: 'notification_settings', label: 'Notification Settings'),
            ],
          ),
      const SettingsMenuItem(
        id: 'security',
        label: 'Security',
        icon: IconType.security,
        subItems: [
          const SettingsSubMenuItem(id: 'security_settings', label: 'Security Settings'),
          const SettingsSubMenuItem(id: 'device_management', label: 'Device Management'),
          const SettingsSubMenuItem(id: 'login_activity', label: 'Login Activity'),
        ],
      ),
      const SettingsMenuItem(
        id: 'preferences',
        label: 'Preferences',
        icon: IconType.preferences,
        subItems: [
          const SettingsSubMenuItem(id: 'preferences_settings', label: 'Preferences Settings'),
        ],
      ),
      const SettingsMenuItem(
        id: 'integrations',
        label: 'Integrations',
        icon: IconType.integrations,
        subItems: [
          const SettingsSubMenuItem(id: 'linked_services', label: 'Linked Services'),
        ],
      ),
      const SettingsMenuItem(
        id: 'support_legal',
        label: 'Support & Legal',
        icon: IconType.supportLegal,
        subItems: [
          const SettingsSubMenuItem(id: 'help_center', label: 'Help Center'),
          const SettingsSubMenuItem(id: 'privacy_policy', label: 'Privacy Policy'),
          const SettingsSubMenuItem(id: 'terms_of_service', label: 'Terms of Service'),
          const SettingsSubMenuItem(id: 'contact_support', label: 'Contact Support'),
        ],
      ),
    ];
  }

    IconData _getIconData(IconType iconType) {
    switch (iconType) {
      case IconType.account:
        return Icons.person_outline;
      case IconType.practice:
        return Icons.business_outlined;
      case IconType.notifications:
        return Icons.notifications_outlined;
      case IconType.security:
        return Icons.security_outlined;
      case IconType.preferences:
        return Icons.tune_outlined;
      case IconType.integrations:
        return Icons.cable_outlined;
      case IconType.supportLegal:
        return Icons.help_outline;
      case IconType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: menuItems.map((item) => _buildMenuItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(SettingsMenuItem item) {
    final isExpanded = expandedMenuId == item.id;
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    // Section header is "active" if any of its sub-items is selected
    final isSectionActive =
        item.subItems?.any((s) => s.id == selectedItemId) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        InkWell(
          onTap: () {
            if (hasSubItems) {
              setState(() {
                expandedMenuId = isExpanded ? null : item.id;
              });
            } else {
              widget.onMenuItemSelected(item.id);
              setState(() => selectedItemId = item.id);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSectionActive ? _tealLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 29,
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconData(item.icon),
                    size: 16,
                    color: _teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSectionActive ? _teal : _textDark,
                    ),
                  ),
                ),
                if (hasSubItems)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: _textMuted,
                  ),
              ],
            ),
          ),
        ),
        // Sub-items
        if (hasSubItems && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2, bottom: 4),
            child: Column(
              children: item.subItems!
                  .map((subItem) => _buildSubMenuItem(subItem))
                  .toList(),
            ),
          ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildSubMenuItem(SettingsSubMenuItem subItem) {
    final isSelected = selectedItemId == subItem.id;

    return InkWell(
      onTap: () {
        widget.onMenuItemSelected(subItem.id);
        setState(() => selectedItemId = subItem.id);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _tealLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? const Border(
                  left: BorderSide(color: _teal, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              subItem.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _teal : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

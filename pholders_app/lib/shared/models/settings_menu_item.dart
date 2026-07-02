/// Icon type enum for settings sidebar menu items.
enum IconType {
  account,
  practice,
  notifications,
  security,
  preferences,
  integrations,
  supportLegal,
  info,
}

/// A top-level settings menu item that can have sub-items.
class SettingsMenuItem {
  final String id;
  final String label;
  final IconType icon;
  final List<SettingsSubMenuItem>? subItems;

  const SettingsMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.subItems,
  });
}

/// A sub-item nested under a [SettingsMenuItem].
class SettingsSubMenuItem {
  final String id;
  final String label;

  const SettingsSubMenuItem({
    required this.id,
    required this.label,
  });
}

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

  const SettingsMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.subItems,
  });
  final String id;
  final String label;
  final IconType icon;
  final List<SettingsSubMenuItem>? subItems;
}

/// A sub-item nested under a [SettingsMenuItem].
class SettingsSubMenuItem {

  const SettingsSubMenuItem({
    required this.id,
    required this.label,
  });
  final String id;
  final String label;
}

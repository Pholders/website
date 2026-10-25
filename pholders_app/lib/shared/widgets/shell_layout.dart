import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'app_sidebar.dart';
import 'app_top_navbar.dart';
import 'pharmacy_sidebar.dart';

/// The shared authenticated shell that wraps every protected page.
///
/// Renders the sidebar on the left and top navbar + content on the right.
/// The sidebar spans full height (logo is inside the sidebar per Figma).
class ShellLayout extends StatefulWidget {

  const ShellLayout({
    super.key,
    required this.role,
    required this.child,
  });
  final String role;
  final Widget child;

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  /// Returns true when the current route is under a settings path.
  bool _isSettingsRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location.contains('/settings');
  }

  Widget _buildSidebar({required bool collapsed, required bool settingsMode}) {
    if (widget.role == AppConstants.rolePharmacy) {
      return PharmacySidebar(collapsed: collapsed || settingsMode);
    }
    return AppSidebar(
      role: widget.role,
      collapsed: collapsed,
      settingsMode: settingsMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final settingsMode = _isSettingsRoute(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: isMobile
          ? Drawer(
              child: _buildSidebar(collapsed: false, settingsMode: false),
            )
          : null,
      body: Row(
        children: [
          // Sidebar spans full height
          if (isDesktop)
            _buildSidebar(collapsed: false, settingsMode: settingsMode),
          if (isTablet)
            _buildSidebar(collapsed: true, settingsMode: settingsMode),

          // Right side: top navbar + page content
          Expanded(
            child: Column(
              children: [
                AppTopNavbar(
                  role: widget.role,
                  onMenuTap: isMobile
                      ? () => Scaffold.of(context).openDrawer()
                      : null,
                ),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

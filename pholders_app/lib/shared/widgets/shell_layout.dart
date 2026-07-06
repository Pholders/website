import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'app_sidebar.dart';
import 'app_top_navbar.dart';

/// The shared authenticated shell that wraps every protected page.
///
/// Renders the sidebar on the left and top navbar + content on the right.
/// The sidebar spans full height (logo is inside the sidebar per Figma).
class ShellLayout extends StatelessWidget {
  final String role;
  final Widget child;

  const ShellLayout({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isTablet = ResponsiveHelper.isTablet(context);
    final bool showRail = isTablet;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: isDesktop
          ? null
          : AppTopNavbar(
              role: role,
              onMenuTap: () => Scaffold.of(context).openDrawer(),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.background,
              child: SafeArea(
                child: AppSidebar(role: role, collapsed: false),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) ...[
            AppSidebar(role: role, collapsed: false),
          ] else if (showRail) ...[
            AppSidebar(role: role, collapsed: true),
          ],
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  AppTopNavbar(role: role, onMenuTap: null),
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'app_sidebar.dart';
import 'app_top_navbar.dart';

/// The shared authenticated shell that wraps every protected page.
///
/// Renders [AppTopNavbar] at the top, [AppSidebar] on the left (desktop),
/// and the page [child] in the remaining space.
///
/// Layout adapts per breakpoint:
/// - Desktop (≥ 1024px): full sidebar + content
/// - Tablet (768–1023px): icon rail + content
/// - Mobile (< 768px): no sidebar; bottom nav or drawer
class ShellLayout extends StatefulWidget {
  /// The role of the authenticated user: 'doctor' or 'pharmacy'.
  final String role;

  /// The current page widget provided by GoRouter's ShellRoute.
  final Widget child;

  const ShellLayout({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      // Mobile: drawer-based navigation
      drawer: isMobile
          ? Drawer(
              child: AppSidebar(role: widget.role, collapsed: false),
            )
          : null,
      body: Column(
        children: [
          // ── Top Navbar ──────────────────────────────────────────────────────
          AppTopNavbar(
            role: widget.role,
            onMenuTap: isMobile
                ? () => Scaffold.of(context).openDrawer()
                : null,
          ),

          // ── Body row ────────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar: full on desktop, icon rail on tablet, hidden on mobile
                if (isDesktop)
                  AppSidebar(role: widget.role, collapsed: false),
                if (isTablet)
                  AppSidebar(role: widget.role, collapsed: true),

                // Page content
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.maxContentWidth,
                    ),
                    child: widget.child,
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

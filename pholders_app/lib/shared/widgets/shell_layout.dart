import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'app_sidebar.dart';
import 'app_top_navbar.dart';
import 'doctor_search_scope.dart';
import 'pharmacy_sidebar.dart';

/// The shared authenticated shell that wraps every protected page.
///
/// Renders the sidebar on the left and top navbar + content on the right.
/// The sidebar spans full height (logo is inside the sidebar per Figma).
///
/// On a desktop window the doctor's shell is laid out on the 1440 × 1024
/// Figma frame and scaled to the window ([fitToWindow]), so every screen shows
/// the design's proportions with nothing pushed below the fold.
class ShellLayout extends StatefulWidget {
  const ShellLayout({
    super.key,
    required this.role,
    required this.child,
  });
  final String role;
  final Widget child;

  /// The Figma frame the doctor pages are drawn on.
  static const Size designFrame = Size(1440, 1024);

  /// How much a window of [window] size scales the design frame: whichever of
  /// width and height is tighter, never enlarged, and not shrunk past the
  /// point where text stops being readable.
  static double fitScale(Size window) => math
      .min(
        1.0,
        math.min(
          window.width / designFrame.width,
          window.height / designFrame.height,
        ),
      )
      .clamp(0.6, 1.0)
      .toDouble();

  /// Lays [child] out as if the window were [window] / [scale], then draws it
  /// [scale] times smaller, so it fills the window exactly. The layout space
  /// is always at least the design frame on the tighter side and wider or
  /// taller on the other, which the flexible layout takes up.
  static Widget fitToWindow({
    required BuildContext context,
    required double scale,
    required Widget child,
  }) {
    final media = MediaQuery.of(context);
    final logical = media.size / scale;
    return MediaQuery(
      data: media.copyWith(size: logical),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: logical, child: child),
      ),
    );
  }

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  /// The top bar's search, read by the dashboard's patients table.
  final _query = ValueNotifier<String>('');
  String? _location;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

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
    // A search belongs to the page it was typed on: start afresh on another.
    // Cleared after this frame: changing it now would rebuild its readers
    // in the middle of building.
    final location = GoRouterState.of(context).matchedLocation;
    if (_location != null && _location != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _query.value = '';
      });
    }
    _location = location;

    final isDoctor = widget.role == AppConstants.roleDoctor;
    final window = MediaQuery.sizeOf(context);
    final scale = ShellLayout.fitScale(window);
    final fit = isDoctor &&
        window.width >= AppTheme.desktopBreakpoint &&
        scale < 1;

    final shell = Builder(builder: _buildShell);
    final scoped = DoctorSearchScope(query: _query, child: shell);
    return fit
        ? ShellLayout.fitToWindow(context: context, scale: scale, child: scoped)
        : scoped;
  }

  Widget _buildShell(BuildContext context) {
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
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Builder(
                    builder: (context) => AppTopNavbar(
                      role: widget.role,
                      onMenuTap: isMobile
                          ? () => Scaffold.of(context).openDrawer()
                          : null,
                    ),
                  ),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility class for determining the current responsive breakpoint.
///
/// Usage:
/// ```dart
/// if (ResponsiveHelper.isDesktop(context)) { ... }
/// ```
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Returns true when the viewport width is below [AppTheme.mobileBreakpoint].
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;

  /// Returns true when the viewport width is between mobile and desktop.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppTheme.mobileBreakpoint &&
        width < AppTheme.desktopBreakpoint;
  }

  /// Returns true when the viewport width is at or above [AppTheme.desktopBreakpoint].
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint;
}

import 'package:flutter/material.dart';

/// Central theme configuration for the PHolders app.
///
/// All colors, text styles, spacing, and breakpoints are defined here.
/// No widget should hardcode these values — always reference AppTheme.
class AppTheme {
  AppTheme._();

  // ─── Breakpoints ────────────────────────────────────────────────────────────
  /// Viewport width below which the layout switches to mobile presentation.
  static const double mobileBreakpoint = 768.0;

  /// Viewport width at or above which the layout uses the tablet presentation.
  static const double tabletBreakpoint = 1024.0;

  /// Viewport width at or above which the full desktop sidebar is shown.
  static const double desktopBreakpoint = 1024.0;

  /// Maximum content width on very wide screens (≥ 1440px).
  static const double maxContentWidth = 1440.0;

  // ─── Sidebar ────────────────────────────────────────────────────────────────
  /// Width of the expanded sidebar on desktop.
  static const double sidebarWidth = 260.0;

  /// Width of the collapsed icon-only rail on tablet.
  static const double sidebarRailWidth = 72.0;

  // ─── Colours ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color secondary = Color(0xFF34A853);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD93025);
  static const Color warning = Color(0xFFF9AB00);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color sidebarBackground = Color(0xFFE8F8F8);
  static const Color sidebarText = Color(0xFF374151);
  static const Color sidebarActiveItem = Color(0xFF309CA3);

  // ─── Spacing ────────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Border radius ──────────────────────────────────────────────────────────
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;

  // ─── MaterialTheme ──────────────────────────────────────────────────────────
  /// The root [ThemeData] used by the [MaterialApp].
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: divider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, space: 1),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
    );
  }
}

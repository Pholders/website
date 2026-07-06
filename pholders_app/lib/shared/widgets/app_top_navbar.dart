import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import '../theme/app_theme.dart';

/// The horizontal top navigation bar matching Figma design.
///
/// Shows breadcrumb (Pholders > PageName), search bar, and notification bell.
class AppTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String role;
  final VoidCallback? onMenuTap;

  const AppTopNavbar({
    super.key,
    required this.role,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  String _getPageName(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.contains('dashboard')) return 'Dashboard';
    if (location.contains('appointments')) return 'Schedule';
    if (location.contains('patients')) return 'Patients';
    if (location.contains('prescriptions')) return 'Prescriptions';
    if (location.contains('billing')) return 'Billing';
    if (location.contains('settings')) return 'Settings';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final pageName = _getPageName(context);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Hamburger (mobile only)
          if (onMenuTap != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
              tooltip: 'Open menu',
            ),
            const SizedBox(width: 8),
          ],

          // Breadcrumb
          Text(
            'Pholders',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '>',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            pageName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),

          const Spacer(),

          // Search bar
          Container(
            width: 320,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6DD0D8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search for patient name, ID, or prescription...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Notification bell
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/bell-icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// The horizontal top navigation bar matching Figma design.
///
/// Shows breadcrumb (Pholders > PageName), search bar, and notification bell.
class AppTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopNavbar({
    super.key,
    required this.role,
    this.onMenuTap,
  });
  final String role;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(86);

  String _getPageName(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.contains('dashboard')) return 'Dashboard';
    if (location.contains('appointments')) return 'Schedule';
    if (location.contains('patients')) return 'Patients';
    if (location.contains('prescriptions')) return 'Prescriptions';
    if (location.contains('orders')) return 'Orders';
    if (location.contains('inventory')) return 'Inventory';
    if (location.contains('dispensing')) return 'Dispensing Queue';
    if (location.contains('reports')) return 'Reports';
    if (location.contains('billing')) return 'Billing';
    if (location.contains('settings')) return 'Settings';
    return 'Dashboard';
  }

  String _getSearchHint() {
    if (role == AppConstants.rolePharmacy) {
      return 'Search for patient or medication...';
    }
    return 'Search for patient name, ID, or prescription...';
  }

  @override
  Widget build(BuildContext context) {
    final pageName = _getPageName(context);

    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 26, 10),
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
          const Text(
            'Pholders',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '>',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            pageName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const Spacer(),

          // Search bar
          Container(
            width: 324,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F8F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSearchHint(),
                    style: const TextStyle(
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
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/icons/bell-icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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

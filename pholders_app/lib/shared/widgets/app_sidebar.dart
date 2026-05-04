import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// A navigation item definition for the sidebar.
class _SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// The left-side navigation panel.
///
/// - [collapsed] = false → full sidebar with labels (desktop)
/// - [collapsed] = true  → icon-only rail (tablet)
///
/// Menu items are role-specific: doctor items vs pharmacy items.
class AppSidebar extends StatelessWidget {
  final String role;

  /// When true, only icons are shown (tablet rail mode).
  final bool collapsed;

  const AppSidebar({
    super.key,
    required this.role,
    required this.collapsed,
  });

  // ─── Doctor navigation items ─────────────────────────────────────────────
  static const List<_SidebarItem> _doctorItems = [
    _SidebarItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: AppRoutes.doctorDashboard,
    ),
    _SidebarItem(
      label: 'Patients',
      icon: Icons.people_outline,
      route: AppRoutes.doctorPatients,
    ),
    _SidebarItem(
      label: 'Prescriptions',
      icon: Icons.medication_outlined,
      route: AppRoutes.doctorPrescriptions,
    ),
    _SidebarItem(
      label: 'Appointments',
      icon: Icons.calendar_today_outlined,
      route: AppRoutes.doctorAppointments,
    ),
    _SidebarItem(
      label: 'Billing & Payments',
      icon: Icons.receipt_long_outlined,
      route: AppRoutes.doctorBilling,
    ),
    _SidebarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppRoutes.doctorSettings,
    ),
  ];

  // ─── Pharmacy navigation items ───────────────────────────────────────────
  static const List<_SidebarItem> _pharmacyItems = [
    _SidebarItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: AppRoutes.pharmacyDashboard,
    ),
    _SidebarItem(
      label: 'Prescriptions',
      icon: Icons.medication_outlined,
      route: AppRoutes.pharmacyPrescriptions,
    ),
    _SidebarItem(
      label: 'Orders',
      icon: Icons.shopping_bag_outlined,
      route: AppRoutes.pharmacyOrders,
    ),
    _SidebarItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      route: AppRoutes.pharmacyInventory,
    ),
    _SidebarItem(
      label: 'Dispensing Queue',
      icon: Icons.queue_outlined,
      route: AppRoutes.pharmacyDispensingQueue,
    ),
    _SidebarItem(
      label: 'Patients',
      icon: Icons.people_outline,
      route: AppRoutes.pharmacyPatients,
    ),
    _SidebarItem(
      label: 'Billing & Payments',
      icon: Icons.receipt_long_outlined,
      route: AppRoutes.pharmacyBilling,
    ),
    _SidebarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppRoutes.pharmacySettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = role == AppConstants.roleDoctor ? _doctorItems : _pharmacyItems;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final width = collapsed ? AppTheme.sidebarRailWidth : AppTheme.sidebarWidth;

    return Container(
      width: width,
      color: AppTheme.sidebarBackground,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = currentLocation.startsWith(item.route);
                return _SidebarTile(
                  item: item,
                  isActive: isActive,
                  collapsed: collapsed,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single sidebar navigation tile.
class _SidebarTile extends StatelessWidget {
  final _SidebarItem item;
  final bool isActive;
  final bool collapsed;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? item.label : '',
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.sidebarActiveItem.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: isActive
                ? Border(
                    left: BorderSide(
                      color: AppTheme.sidebarActiveItem,
                      width: 3,
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.only(
            left: isActive ? AppTheme.spacingMd - 3 : AppTheme.spacingMd,
            right: AppTheme.spacingMd,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive
                    ? AppTheme.sidebarActiveItem
                    : AppTheme.sidebarText,
              ),
              if (!collapsed) ...[
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? AppTheme.sidebarActiveItem
                          : AppTheme.sidebarText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import 'package:pholders_app/shared/theme/app_theme.dart';

/// A grouped section in the pharmacy sidebar.
class _SidebarSection {

  const _SidebarSection({
    required this.title,
    required this.iconAsset,
    required this.items,
  });
  final String title;
  final String iconAsset;
  final List<_SidebarSubItem> items;
}

/// A sub-item within a sidebar section.
class _SidebarSubItem {

  const _SidebarSubItem({required this.label, required this.route});
  final String label;
  // route can be nullable (AppRoutes may return String?)
  final String? route;
}

/// Pharmacy-specific sidebar matching the Figma design.
///
/// Uses grouped sections (Main, Operations, Customers, Insights, Financial, System)
/// with sub-items under each header inside a light grey rounded container.
/// Logout button is separate at the bottom with its own rounded container.
class PharmacySidebar extends StatelessWidget {

  const PharmacySidebar({
    super.key,
    required this.collapsed,
  });
  final bool collapsed;

  // Use AppTheme tokens for colors and spacing

  // ─── Sections ────────────────────────────────────────────────────────────
  static final List<_SidebarSection> _sections = [
    const _SidebarSection(
      title: 'Main',
      iconAsset: 'assets/icons/main-icon.png',
      items: [
        _SidebarSubItem(label: 'Dashboard', route: AppRoutes.pharmacyDashboard),
        _SidebarSubItem(
            label: 'Prescriptions', route: AppRoutes.pharmacyPrescriptions),
        _SidebarSubItem(label: 'Orders', route: AppRoutes.pharmacyOrders),
      ],
    ),
    const _SidebarSection(
      title: 'Operations',
      iconAsset: 'assets/icons/operations-icon.png',
      items: [
        _SidebarSubItem(label: 'Inventory', route: AppRoutes.pharmacyInventory),
        _SidebarSubItem(
            label: 'Dispensing Queue', route: AppRoutes.pharmacyDispensingQueue),
      ],
    ),
    const _SidebarSection(
      title: 'Customers',
      iconAsset: 'assets/icons/customers-icon.png',
      items: [
        _SidebarSubItem(label: 'Patients', route: AppRoutes.pharmacyPatients),
      ],
    ),
    _SidebarSection(
      title: 'Insights',
      iconAsset: 'assets/icons/Insights-icon.png',
      items: [
        _SidebarSubItem(label: 'Reports', route: AppRoutes.pharmacyReports),
      ],
    ),
    const _SidebarSection(
      title: 'Financial',
      iconAsset: 'assets/icons/financial-icon.png',
      items: [
        _SidebarSubItem(
            label: 'Billing & Payments', route: AppRoutes.pharmacyBilling),
      ],
    ),
    const _SidebarSection(
      title: 'System',
      iconAsset: 'assets/icons/system-icon.png',
      items: [
        _SidebarSubItem(label: 'Settings', route: AppRoutes.pharmacySettings),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final width = collapsed ? AppTheme.sidebarRailWidth : AppTheme.sidebarWidth;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 12 : 20,
              vertical: 20,
            ),
            child: Align(
              alignment: collapsed ? Alignment.center : Alignment.centerLeft,
              child: Image.asset(
                'assets/icons/PHolders-icon.png',
                width: collapsed ? 36 : 56,
                height: collapsed ? 36 : 56,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ── Sections (light grey rounded container) ──────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 8 : 12,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 0,
                  right: collapsed ? 4 : 12,
                  top: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in _sections) ...[
                      if (!collapsed)
                        _SectionHeader(
                          title: section.title,
                          iconAsset: section.iconAsset,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Image.asset(
                              section.iconAsset,
                              width: 20,
                              height: 20,
                              color: AppTheme.sidebarText,
                            ),
                          ),
                        ),
                      for (final item in section.items) ...[
                        _SubItemTile(
                          item: item,
                          // guard against nullable routes from AppRoutes
                          isActive: (item.route ?? '').isNotEmpty &&
                              (currentLocation == (item.route ?? '') ||
                                  currentLocation.startsWith(item.route ?? '')),
                          collapsed: collapsed,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Logout (separate rounded container, flat bottom) ────────────
          Padding(
            padding: EdgeInsets.only(
              left: collapsed ? 12 : 24,
              right: collapsed ? 12 : 24,
              bottom: 0,
              top: 24,
            ),
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              onTap: () => context.go(AppRoutes.login),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 12 : 24,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.sidebarActiveItem,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: collapsed ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    if (!collapsed) ...[
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sidebarText,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Image.asset(
                      'assets/icons/logout-icon.png',
                      width: 20,
                      height: 20,
                      color: AppTheme.sidebarText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with asset icon and title.
class _SectionHeader extends StatelessWidget {

  const _SectionHeader({required this.title, required this.iconAsset});
  final String title;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 3, left: 16),
      child: Row(
        children: [
          Image.asset(
            iconAsset,
            width: 18,
            height: 18,
            color: AppTheme.sidebarText,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.sidebarText,
            ),
          ),
        ],
      ),
    );
  }
}

/// A sub-item tile within a section.
class _SubItemTile extends StatelessWidget {

  const _SubItemTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
  });
  final _SidebarSubItem item;
  final bool isActive;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? item.label : '',
      child: InkWell(
        onTap: (item.route ?? '').isNotEmpty ? () => context.go(item.route!) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              // Active indicator line — flush left, rounded right edges
              Container(
                width: isActive ? 4 : 0,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.sidebarActiveItem,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              // Spacer between indicator and content
              const SizedBox(width: 16),
              // Item content
              Expanded(
                child: Container(
                  height: 34,
                  padding: EdgeInsets.only(
                    left: collapsed ? 8 : 12,
                    right: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.sidebarBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      if (collapsed)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppTheme.sidebarActiveItem
                                // ignore: deprecated_member_use
                                : AppTheme.textSecondary.withOpacity(0.4),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? AppTheme.sidebarActiveItem : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
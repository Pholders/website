import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/logout.dart';
import '../../core/routing/app_routes.dart';
import '../theme/app_theme.dart';

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
  final String route;
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

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _activeColor = Color(0xFF309CA3);
  static const Color _activeBg = Color(0xFFD9F5F5);
  static const Color _sectionTitleColor = Color(0xFF1F2937);
  static const Color _subItemColor = Color(0xFF6B7280);
  static const Color _logoutColor = Color(0xFF1F2937);
  static const Color _navBgColor = Color(0xFFF3F5F5);
  static const Color _logoutBgColor = Color(0xFFF3F4F6);

  // ─── Sections ────────────────────────────────────────────────────────────
  static const List<_SidebarSection> _sections = [
    _SidebarSection(
      title: 'Main',
      iconAsset: 'assets/main-icon.png',
      items: [
        _SidebarSubItem(label: 'Dashboard', route: AppRoutes.pharmacyDashboard),
        _SidebarSubItem(
            label: 'Prescriptions', route: AppRoutes.pharmacyPrescriptions),
        _SidebarSubItem(label: 'Orders', route: AppRoutes.pharmacyOrders),
      ],
    ),
    _SidebarSection(
      title: 'Operations',
      iconAsset: 'assets/operations-icon.png',
      items: [
        _SidebarSubItem(label: 'Inventory', route: AppRoutes.pharmacyInventory),
        _SidebarSubItem(
            label: 'Dispensing Queue', route: AppRoutes.pharmacyDispensingQueue),
      ],
    ),
    _SidebarSection(
      title: 'Customers',
      iconAsset: 'assets/customers-icon.png',
      items: [
        _SidebarSubItem(label: 'Patients', route: AppRoutes.pharmacyPatients),
      ],
    ),
    _SidebarSection(
      title: 'Insights',
      iconAsset: 'assets/Insights-icon.png',
      items: [
        _SidebarSubItem(label: 'Reports', route: AppRoutes.pharmacyReports),
      ],
    ),
    _SidebarSection(
      title: 'Financial',
      iconAsset: 'assets/financial-icon.png',
      items: [
        _SidebarSubItem(
            label: 'Billing & Payments', route: AppRoutes.pharmacyBilling),
      ],
    ),
    _SidebarSection(
      title: 'System',
      iconAsset: 'assets/system-icon.png',
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
        color: _bgColor,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
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
                'assets/PHolders-icon.png',
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
                  color: _navBgColor,
                  borderRadius: BorderRadius.circular(16),
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
                              color: _sectionTitleColor,
                            ),
                          ),
                        ),
                      for (final item in section.items)
                        _SubItemTile(
                          item: item,
                          isActive: currentLocation == item.route ||
                              currentLocation.startsWith(item.route),
                          collapsed: collapsed,
                        ),
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
              onTap: () => performLogout(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 12 : 24,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF6DD0D8),
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
                          color: _logoutColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Image.asset(
                      'assets/logout-icon.png',
                      width: 20,
                      height: 20,
                      color: _logoutColor,
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
            color: PharmacySidebar._sectionTitleColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PharmacySidebar._sectionTitleColor,
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
        onTap: () => context.go(item.route),
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
                  color: PharmacySidebar._activeColor,
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
                    color: isActive
                        ? PharmacySidebar._activeBg
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
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
                                ? PharmacySidebar._activeColor
                                : PharmacySidebar._subItemColor
                                    .withValues(alpha: 0.4),
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
                              color: isActive
                                  ? PharmacySidebar._activeColor
                                  : PharmacySidebar._subItemColor,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/constants/app_constants.dart';

class _SidebarItem {
  const _SidebarItem({
    required this.iconAsset,
    required this.route,
    required this.tooltip,
  });

  final String iconAsset;
  final String route;
  final String tooltip;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.role,
    required this.collapsed,
    required void Function(dynamic route) onItemSelected,
  });

  final String role;
  final bool collapsed;

  static const Color _activeColor = Color(0xFF2FAAA2);
  static const Color _railColor = Color(0xFFF7F7F7);

  static const List<_SidebarItem> _doctorItems = [
    _SidebarItem(
        iconAsset: 'assets/icons/dashboard-icon.png',
        route: AppRoutes.doctorDashboard,
        tooltip: 'Dashboard'),
    _SidebarItem(
        iconAsset: 'assets/icons/patients-icon.png',
        route: AppRoutes.doctorPatients,
        tooltip: 'Patients'),
    _SidebarItem(
        iconAsset: 'assets/icons/prescription-icon.png',
        route: AppRoutes.doctorPrescriptions,
        tooltip: 'Prescriptions'),
    _SidebarItem(
        iconAsset: 'assets/icons/appointments-icon.png',
        route: AppRoutes.doctorAppointments,
        tooltip: 'Appointments'),
    _SidebarItem(
        iconAsset: 'assets/icons/billing-icon.png',
        route: AppRoutes.doctorBilling,
        tooltip: 'Billing'),
    _SidebarItem(
        iconAsset: 'assets/icons/settings-icon.png',
        route: AppRoutes.doctorSettings,
        tooltip: 'Settings'),
    _SidebarItem(
        iconAsset: 'assets/icons/help-icon.png',
        route: AppRoutes.doctorSettings,
        tooltip: 'Help'),
  ];

  static const List<_SidebarItem> _pharmacyItems = [
    _SidebarItem(
        iconAsset: 'assets/icons/dashboard-icon.png',
        route: AppRoutes.pharmacyDashboard,
        tooltip: 'Dashboard'),
    _SidebarItem(
        iconAsset: 'assets/icons/prescription-icon.png',
        route: AppRoutes.pharmacyPrescriptions,
        tooltip: 'Prescriptions'),
    _SidebarItem(
        iconAsset: 'assets/icons/billing-icon.png',
        route: AppRoutes.pharmacyOrders,
        tooltip: 'Orders'),
    _SidebarItem(
        iconAsset: 'assets/icons/settings-icon.png',
        route: AppRoutes.pharmacyInventory,
        tooltip: 'Inventory'),
    _SidebarItem(
        iconAsset: 'assets/icons/appointments-icon.png',
        route: AppRoutes.pharmacyDispensingQueue,
        tooltip: 'Dispensing Queue'),
    _SidebarItem(
        iconAsset: 'assets/icons/patients-icon.png',
        route: AppRoutes.pharmacyPatients,
        tooltip: 'Patients'),
    _SidebarItem(
        iconAsset: 'assets/icons/billing-icon.png',
        route: AppRoutes.pharmacyBilling,
        tooltip: 'Billing'),
    _SidebarItem(
        iconAsset: 'assets/icons/settings-icon.png',
        route: AppRoutes.pharmacySettings,
        tooltip: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final items =
        role == AppConstants.roleDoctor ? _doctorItems : _pharmacyItems;
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 120,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Image.asset(
            'assets/icons/PHolders-icon.png',
            width: 70,
            height: 70,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 44),
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _railColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  _SidebarTile(
                    item: item,
                    active: currentLocation.startsWith(item.route),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE3FAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Icon(Icons.logout_outlined,
                size: 26, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.active});

  final _SidebarItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.tooltip,
      child: InkWell(
        onTap: () => context.go(item.route),
        child: SizedBox(
          height: 45,
          width: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                const Positioned(
                  left: 0,
                  child: SizedBox(
                    width: 4,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppSidebar._activeColor,
                        borderRadius:
                            BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              Image.asset(
                item.iconAsset,
                width: 22,
                height: 22,
                color: active ? AppSidebar._activeColor : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

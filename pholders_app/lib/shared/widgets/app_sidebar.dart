import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/auth/auth_actions.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// A navigation item definition for the sidebar.
class _SidebarItem {

  const _SidebarItem({
    required this.label,
    required this.iconAsset,
    required this.route,
  });
  final String label;
  final String iconAsset;
  final String route;
}

/// The left-side navigation panel matching the Figma design.
///
/// Light mint background, PHolders logo at top, nav items with teal active
/// indicator, "Activate Membership" card, and doctor profile at bottom.
class AppSidebar extends StatelessWidget {

  const AppSidebar({
    super.key,
    required this.role,
    required this.collapsed,
    this.settingsMode = false,
  });
  final String role;
  final bool collapsed;
  /// When true the sidebar shows icons only (used on settings pages to save space).
  final bool settingsMode;

  // ─── Colors matching Figma ───────────────────────────────────────────────
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _activeColor = Color(0xFF309CA3);
  static const Color _textColor = Color(0xFF374151);
  static const Color _membershipBg = Color(0xFF000000);

  // ─── Doctor navigation items ─────────────────────────────────────────────
  static const List<_SidebarItem> _doctorItems = [
    _SidebarItem(
      label: 'Dashboard',
      iconAsset: 'assets/dashboard-icon.png',
      route: AppRoutes.doctorDashboard,
    ),
    _SidebarItem(
      label: 'Patients',
      iconAsset: 'assets/patients-icon.png',
      route: AppRoutes.doctorPatients,
    ),
    // New Script and Search Scripts are off the menu: writing a script starts
    // from New Prescription on the Prescriptions screen, and that screen
    // already lists and filters them. Both pages and their routes are still
    // there — only the sidebar entries are gone.
    _SidebarItem(
      label: 'Prescriptions',
      iconAsset: 'assets/prescription-icon.png',
      route: AppRoutes.doctorPrescriptions,
    ),
    _SidebarItem(
      label: 'Appointments',
      iconAsset: 'assets/appointments-icon.png',
      route: AppRoutes.doctorAppointments,
    ),
    _SidebarItem(
      label: 'Sick Notes',
      iconAsset: 'assets/prescription-icon.png',
      route: AppRoutes.doctorSickNotes,
    ),
    _SidebarItem(
      label: 'Billing & Payments',
      iconAsset: 'assets/billing-icon.png',
      route: AppRoutes.doctorBilling,
    ),
    _SidebarItem(
      label: 'Settings',
      iconAsset: 'assets/settings-icon.png',
      route: AppRoutes.doctorSettings,
    ),
  ];

  // ─── Pharmacy navigation items ───────────────────────────────────────────
  static const List<_SidebarItem> _pharmacyItems = [
    _SidebarItem(
      label: 'Dashboard',
      iconAsset: 'assets/dashboard-icon.png',
      route: AppRoutes.pharmacyDashboard,
    ),
    _SidebarItem(
      label: 'Prescriptions',
      iconAsset: 'assets/prescription-icon.png',
      route: AppRoutes.pharmacyPrescriptions,
    ),
    _SidebarItem(
      label: 'Orders',
      iconAsset: 'assets/billing-icon.png',
      route: AppRoutes.pharmacyOrders,
    ),
    _SidebarItem(
      label: 'Inventory',
      iconAsset: 'assets/settings-icon.png',
      route: AppRoutes.pharmacyInventory,
    ),
    _SidebarItem(
      label: 'Dispensing Queue',
      iconAsset: 'assets/appointments-icon.png',
      route: AppRoutes.pharmacyDispensingQueue,
    ),
    _SidebarItem(
      label: 'Patients',
      iconAsset: 'assets/patients-icon.png',
      route: AppRoutes.pharmacyPatients,
    ),
    _SidebarItem(
      label: 'Billing & Payments',
      iconAsset: 'assets/billing-icon.png',
      route: AppRoutes.pharmacyBilling,
    ),
    _SidebarItem(
      label: 'Settings',
      iconAsset: 'assets/settings-icon.png',
      route: AppRoutes.pharmacySettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items =
        role == AppConstants.roleDoctor ? _doctorItems : _pharmacyItems;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    // In settings mode, always show icons only regardless of responsive state
    final isIconOnly = settingsMode || collapsed;
    final width = isIconOnly ? AppTheme.sidebarRailWidth : AppTheme.sidebarWidth;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 64,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                // ── Logo ─────────────────────────────────────────────────────────
                if (!isIconOnly) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/PHolders-icon.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/PHolders-icon.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                ],

          // ── Nav items ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = currentLocation.startsWith(item.route);
                return _SidebarTile(
                  item: item,
                  isActive: isActive,
                  collapsed: isIconOnly,
                );
              }),
            ),
          ),

          const Spacer(),

          const SizedBox(height: 16),

          // ── Activate Membership card ─────────────────────────────────────
          if (!isIconOnly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _membershipBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activate Membership',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check your benefits',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _activeColor, width: 1.5),
                      ),
                      child: const Text(
                        'Check now',
                        style: TextStyle(
                          color: _activeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Doctor profile ───────────────────────────────────────────────
          if (!isIconOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Doctor photo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      image: const DecorationImage(
                        image: AssetImage('assets/doctors.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name bar — the signed-in user, and logout.
                  const _SignedInUserBar(),
                ],
              ),
            ),
          const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single sidebar navigation tile matching Figma design.
class _SidebarTile extends StatelessWidget {

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
  });
  final _SidebarItem item;
  final bool isActive;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? item.label : '',
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isActive && !collapsed
                ? const Border(
                    left: BorderSide(
                      color: AppSidebar._activeColor,
                      width: 4,
                    ),
                  )
                : null,
          ),
          // When collapsed: center the icon. When expanded: normal padding.
          padding: collapsed
              ? EdgeInsets.zero
              : EdgeInsets.only(
                  left: isActive ? 12 : 16,
                  right: 16,
                ),
          child: collapsed
              ? Center(
                  child: Image.asset(
                    item.iconAsset,
                    width: 20,
                    height: 20,
                    color: isActive
                        ? AppSidebar._activeColor
                        : AppSidebar._textColor,
                  ),
                )
              : Row(
                  children: [
                    Image.asset(
                      item.iconAsset,
                      width: 20,
                      height: 20,
                      color: isActive
                          ? AppSidebar._activeColor
                          : AppSidebar._textColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppSidebar._activeColor
                              : AppSidebar._textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Shows who is signed in and logs them out when tapped.
///
/// Reads the name from the Redux store rather than hardcoding it, so it
/// reflects the account that actually authenticated.
class _SignedInUserBar extends StatelessWidget {
  const _SignedInUserBar();

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) {
        final auth = store.state.authState;
        // Prefer the full profile once it has loaded — it carries the proper
        // first/last name rather than whatever the login summary returned.
        if (auth.isDoctor) {
          return auth.doctor?.displayName ??
              (auth.userName == null ? 'Doctor' : 'Dr ${auth.userName}');
        }
        return auth.userName ?? 'Account';
      },
      builder: (context, displayName) {
        return Material(
          color: const Color(0xFFD9F5F5),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              // The router guard sends the user to /login once the store
              // reports no session, so no explicit navigation is needed.
              StoreProvider.of<AppState>(context).dispatch(const LogoutAction());
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppSidebar._textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.logout_outlined,
                      size: 18, color: AppSidebar._textColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

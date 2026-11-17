import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/auth/auth_actions.dart';
import '../../core/network/secure_url.dart';
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
/// White background, PHolders logo at top, nav items on a light card with a
/// pale teal pill and teal edge marker for the active one, the "Activate
/// Membership" card, and the doctor's photo and name at the bottom.
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

  /// Width when expanded, from the Figma frame: the menu card, membership
  /// card and profile sit 40–300px in from the left.
  static const double expandedWidth = 310;

  // ─── Colors matching Figma ───────────────────────────────────────────────
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _menuBg = Color(0xFFF5F7F7);
  static const Color _activePill = Color(0xFFE0F4F5);
  static const Color _indicator = Color(0xFF48BFC4);
  static const Color _aqua = Color(0xFF6DD0D8);
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
    // Opens the Support & Legal settings page, which has the contact form.
    _SidebarItem(
      label: 'Help & Support',
      iconAsset: 'assets/help-icon.png',
      route: AppRoutes.doctorSettingsSupportLegal,
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
    // The item whose route is the longest match for where we are, so that
    // Help & Support (under /settings) is not also shown as Settings.
    final active = _activeRoute(items, currentLocation);
    // In settings mode, always show icons only regardless of responsive state
    final isIconOnly = settingsMode || collapsed;
    final width = isIconOnly ? AppTheme.sidebarRailWidth : expandedWidth;

    // The sidebar never scrolls. It fills the window's height, the gap above
    // the membership card taking up any spare; on a window too short for it,
    // the whole sidebar is drawn smaller to fit instead.
    return Container(
      width: width,
      color: _bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo ─────────────────────────────────────────────────────
                    if (!isIconOnly) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Image.asset(
                          'assets/PHolders-icon.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Image.asset(
                          'assets/PHolders-icon.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Nav items ────────────────────────────────────────────────
                    Container(
                      margin: isIconOnly
                          ? const EdgeInsets.symmetric(horizontal: 8)
                          : const EdgeInsets.only(left: 42, right: 20),
                      padding: isIconOnly
                          ? const EdgeInsets.symmetric(vertical: 8)
                          : const EdgeInsets.fromLTRB(16, 12, 4, 12),
                      decoration: BoxDecoration(
                        color: _menuBg,
                        borderRadius:
                            BorderRadius.circular(isIconOnly ? 16 : 28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in items)
                            _SidebarTile(
                              item: item,
                              isActive: item.route == active,
                              collapsed: isIconOnly,
                            ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 16),

                    // ── Activate Membership card ─────────────────────────────────
                    if (!isIconOnly) ...[
                      Container(
                        width: 250,
                        margin: const EdgeInsets.only(left: 46),
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        decoration: BoxDecoration(
                          color: _membershipBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activate Membership',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Check your benefits',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _aqua, width: 1.2),
                              ),
                              child: const Text(
                                'Check now',
                                style: TextStyle(color: _aqua, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Doctor profile ───────────────────────────────────────────
                    if (!isIconOnly)
                      const Padding(
                        padding: EdgeInsets.only(left: 47, right: 9),
                        child: _ProfileBlock(),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The route of the item to highlight: the longest one [location] is under.
  static String? _activeRoute(List<_SidebarItem> items, String location) {
    String? best;
    for (final item in items) {
      final under =
          location == item.route || location.startsWith('${item.route}/');
      if (under && (best == null || item.route.length > best.length)) {
        best = item.route;
      }
    }
    return best;
  }
}

/// The doctor's photo on its card, with the name bar laid over the card's
/// foot, as in the design: the card is narrower than the bar and centred on
/// it, and the bar overlaps its bottom edge.
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock();

  static const double photoWidth = 183;
  static const double photoHeight = 165;
  static const double barHeight = 63;
  static const double overlap = 14;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: photoHeight + barHeight - overlap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            width: photoWidth,
            height: photoHeight,
            // The signed-in doctor's own photo.
            child: _SidebarPhoto(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            // Name bar — the signed-in user, and logout.
            child: _SignedInUserBar(),
          ),
        ],
      ),
    );
  }
}

/// The signed-in doctor's own photo, on the light card the name bar overlaps.
/// Shown whole: a portrait fills the card's height, a wider photo its width.
///
/// Falls back to a plain silhouette before a profile has loaded, when no
/// photo has been uploaded, and when one fails to load. Never a stock photo:
/// a stranger's face in the doctor's place reads as someone else's account.
class _SidebarPhoto extends StatelessWidget {
  const _SidebarPhoto();

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String?>(
      // A stored URL can say http:// even though the host only serves HTTPS.
      converter: (store) =>
          secureImageUrl(store.state.authState.doctor?.profileImage),
      builder: (context, url) {
        const placeholder = FittedBox(
          key: ValueKey('no-photo'),
          alignment: Alignment.bottomCenter,
          child: Icon(Icons.person, color: Color(0xFFC9D3D4)),
        );
        return Container(
          clipBehavior: Clip.antiAlias,
          // The photo stands on the bar, so its foot is hidden under it.
          padding: const EdgeInsets.only(bottom: _ProfileBlock.overlap),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: url == null || url.isEmpty
              ? placeholder
              // The whole photo, never cropped.
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, _, __) => placeholder,
                ),
        );
      },
    );
  }
}

/// A single sidebar navigation tile matching Figma design: black icon and
/// label, and when active a pale teal pill with a teal bar at the menu's edge.
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
    final icon = Image.asset(
      item.iconAsset,
      width: collapsed ? 22 : 26,
      height: collapsed ? 22 : 26,
      color: isActive ? AppSidebar._indicator : Colors.black,
    );

    return Tooltip(
      message: collapsed ? item.label : '',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: isActive ? AppSidebar._activePill : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                onTap: () => context.go(item.route),
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  height: collapsed ? 44 : 46,
                  child: collapsed
                      ? Center(child: icon)
                      : Padding(
                          padding: const EdgeInsets.only(left: 19, right: 4),
                          child: Row(
                            children: [
                              icon,
                              const SizedBox(width: 22),
                              Expanded(
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: isActive
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            // The teal marker sits on the menu card's left edge.
            if (isActive && !collapsed)
              Positioned(
                left: -18,
                top: 7,
                bottom: 7,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: AppSidebar._indicator,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
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
          color: AppSidebar._activePill,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // The router guard sends the user to /login once the store
              // reports no session, so no explicit navigation is needed.
              StoreProvider.of<AppState>(context)
                  .dispatch(const LogoutAction());
            },
            child: SizedBox(
              height: _ProfileBlock.barHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: 19, right: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Log out',
                      child: CustomPaint(
                        size: Size(30, 34),
                        painter: _ExitDoorPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The design's log-out mark: an open door in its frame, with an arrow
/// leaving through the doorway.
class _ExitDoorPainter extends CustomPainter {
  const _ExitDoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pen = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The frame, open on the right where the arrow leaves.
    final frame = Path()
      ..moveTo(w * 0.62, h * 0.36)
      ..lineTo(w * 0.62, h * 0.06)
      ..lineTo(w * 0.08, h * 0.06)
      ..lineTo(w * 0.08, h * 0.94)
      ..lineTo(w * 0.62, h * 0.94)
      ..lineTo(w * 0.62, h * 0.64);
    canvas.drawPath(frame, pen);

    // The door swung open, hinged on the left.
    final door = Path()
      ..moveTo(w * 0.08, h * 0.06)
      ..lineTo(w * 0.36, h * 0.16)
      ..lineTo(w * 0.36, h * 0.98)
      ..lineTo(w * 0.08, h * 0.94);
    canvas.drawPath(door, pen);
    canvas.drawCircle(
      Offset(w * 0.29, h * 0.55),
      1.2,
      Paint()..color = Colors.black87,
    );

    // The arrow out.
    final y = h * 0.5;
    canvas.drawLine(Offset(w * 0.48, y), Offset(w * 0.96, y), pen);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.84, y - h * 0.08)
        ..lineTo(w * 0.96, y)
        ..lineTo(w * 0.84, y + h * 0.08),
      pen,
    );
  }

  @override
  bool shouldRepaint(_ExitDoorPainter oldDelegate) => false;
}

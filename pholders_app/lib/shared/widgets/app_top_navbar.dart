import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/routing/app_routes.dart';
import '../../features/doctor/notifications/data/doctor_notifications_repository.dart';
import '../../shared/constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'doctor_search_scope.dart';

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
  Size get preferredSize => const Size.fromHeight(height);

  /// From the Figma frame: the page panel starts 98px down.
  static const double height = 98;

  String _getPageName(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.contains('dashboard')) return 'Dashboard';
    if (location.contains('appointments')) return 'Schedule';
    if (location.contains('patients')) return 'Patients';
    if (location.contains('notifications')) return 'Notifications';
    if (location.contains('prescriptions')) return 'Prescriptions';
    if (location.contains('orders')) return 'Orders';
    if (location.contains('inventory')) return 'Inventory';
    if (location.contains('dispensing')) return 'Dispensing Queue';
    if (location.contains('reports')) return 'Reports';
    if (location.contains('billing')) return 'Billing';
    if (location.contains('settings')) return 'Settings';
    return 'Dashboard';
  }

  /// The doctor pages whose patients table the top bar's search filters.
  static bool _searchesPatients(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location == AppRoutes.doctorDashboard ||
        location == AppRoutes.doctorPatients;
  }

  String _getSearchHint() => 'Search for patient or medication...';

  @override
  Widget build(BuildContext context) {
    final pageName = _getPageName(context);
    final isPharmacy = role == AppConstants.rolePharmacy;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
      ),
      padding: const EdgeInsets.only(left: 32, right: 38),
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
            style: TextStyle(fontSize: 17, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF8A8A8A)),
          const SizedBox(width: 6),
          Text(
            pageName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),

          const Spacer(),

          // A search box that searched nothing: it was drawn as text, not a
          // field. Doctors search on the pages that have something to search
          // (Patients, Appointments, Prescriptions, Billing), so it is gone
          // for them. The pharmacy side is left as it was.
          if (isPharmacy) Container(
            width: 300,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
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

          // The doctor's search, on the two pages that read it: the dashboard
          // and the Patients list, where it filters the patients table. Shown
          // only inside a shell that shares the query with the page, so it
          // always searches something.
          if (!isPharmacy && _searchesPatients(context))
            if (DoctorSearchScope.maybeOf(context) case final query?)
              _DoctorSearchField(query: query),

          const SizedBox(width: 26),

          // Notification bell
          InkWell(
            onTap: isPharmacy 
                ? () => context.go(AppRoutes.pharmacyNotifications)
                : () => context.go(AppRoutes.doctorNotifications),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    image: AssetImage('assets/bell-icon.png'),
                    width: 32,
                    height: 32,
                  ),
                ),
                if (isPharmacy)
                  const Positioned(right: 6, top: 6, child: _RedDot())
                else
                  const Positioned(right: 0, top: 2, child: _DoctorUnreadDot()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pale teal search pill from the design, a real text field.
class _DoctorSearchField extends StatefulWidget {
  const _DoctorSearchField({required this.query});

  final ValueNotifier<String> query;

  @override
  State<_DoctorSearchField> createState() => _DoctorSearchFieldState();
}

class _DoctorSearchFieldState extends State<_DoctorSearchField> {
  late final _controller = TextEditingController(text: widget.query.value);

  @override
  void initState() {
    super.initState();
    widget.query.addListener(_follow);
  }

  @override
  void dispose() {
    widget.query.removeListener(_follow);
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the box in step when the shell clears the query.
  void _follow() {
    if (_controller.text != widget.query.value) {
      _controller.text = widget.query.value;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 410,
      height: 41,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F8),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 24, color: Color(0xFF1F2A2C)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) => widget.query.value = v,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Search for patient name, ID, or visit reason...',
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFFA3B1B3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.query.value.isNotEmpty)
            IconButton(
              tooltip: 'Clear search',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () => widget.query.value = '',
              icon: const Icon(Icons.close, color: Color(0xFF7C8B8D)),
            ),
        ],
      ),
    );
  }
}

class _RedDot extends StatelessWidget {
  const _RedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

/// The doctor's bell shows how many notifications are unread, and nothing when
/// none are. It used to show a plain dot always. Checks the count each time the
/// bar is built for a new page, and follows the Notifications page as the
/// doctor reads.
class _DoctorUnreadDot extends StatefulWidget {
  const _DoctorUnreadDot();

  @override
  State<_DoctorUnreadDot> createState() => _DoctorUnreadDotState();
}

class _DoctorUnreadDotState extends State<_DoctorUnreadDot> {
  DoctorNotificationsRepository? get _repo =>
      sl.isRegistered<DoctorNotificationsRepository>()
          ? sl<DoctorNotificationsRepository>()
          : null;

  @override
  void initState() {
    super.initState();
    // A failed check leaves the last known count; the bell is not worth an error.
    _repo?.refreshUnread().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: repo.unread,
      builder: (context, unread, _) {
        if (unread <= 0) return const SizedBox.shrink();
        return Semantics(
          label: '$unread unread notification${unread == 1 ? '' : 's'}',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

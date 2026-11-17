import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../data/doctor_notifications_repository.dart';

/// The doctor's notifications: bookings to accept, cancellations and moves,
/// dispensed scripts and new reviews, from /users/doctor/notifications.
///
/// It used to show six invented notifications ("Patient John Doe has
/// requested a prescription refill", a login alert, a failed medical aid
/// check), and reading or deleting one changed only the screen.
class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key, this.repository});

  final DoctorNotificationsRepository? repository;

  @override
  State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  late final DoctorNotificationsRepository _repo =
      widget.repository ?? sl<DoctorNotificationsRepository>();

  List<DoctorNotification> notifications = const [];
  bool _loading = true;
  String? _error;
  String selectedFilter = 'all';
  int? expandedNotificationId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.fetch();
      if (!mounted) return;
      setState(() {
        notifications = rows;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  int get _unread => notifications.where((n) => !n.isRead).length;

  List<DoctorNotification> get filteredNotifications {
    if (selectedFilter == 'all') return notifications;
    if (selectedFilter == 'unread') return notifications.where((n) => !n.isRead).toList();
    return notifications.where((n) => n.kind.name == selectedFilter).toList();
  }

  /// Applies [change] at once, saves it, and puts the list back with a
  /// message if the server refuses.
  Future<void> _optimistic(
    List<DoctorNotification> Function(List<DoctorNotification>) change,
    Future<void> Function() save,
    String failure,
  ) async {
    final before = notifications;
    setState(() => notifications = change(notifications));
    _repo.unread.value = _unread;
    try {
      await save();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => notifications = before);
      _repo.unread.value = _unread;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failure: ${e.message}')),
      );
    }
  }

  void _setRead(DoctorNotification n, bool read) => _optimistic(
        (list) => [for (final x in list) x.id == n.id ? x.copyWith(isRead: read) : x],
        () => _repo.setRead(n.id, read: read),
        'Could not update the notification',
      );

  void _deleteNotification(DoctorNotification n) => _optimistic(
        (list) => list.where((x) => x.id != n.id).toList(),
        () => _repo.delete(n.id),
        'Could not delete the notification',
      );

  void _markAllAsRead() => _optimistic(
        (list) => [for (final x in list) x.copyWith(isRead: true)],
        _repo.markAllRead,
        'Could not mark them read',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Scrollable content ─────────────────────────────────────────
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 220), // Space for fixed header
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF309CA3))),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else if (filteredNotifications.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: [
                          for (final n in filteredNotifications)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildNotificationCard(n),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // ── Fixed Header ───────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F8),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFD1F5F5)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD1F5F5)),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Color(0xFF309CA3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF309CA3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_unread unread',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_unread > 0)
                          _headerButton(Icons.done_all_rounded, 'Mark all read', _markAllAsRead),
                        const SizedBox(width: 8),
                        _headerButton(Icons.refresh_rounded, 'Refresh', _loading ? null : _load),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${filteredNotifications.length} notification${filteredNotifications.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1F5F5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF309CA3), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF309CA3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('appointment', 'Appointments'),
      ('prescription', 'Prescriptions'),
      ('review', 'Reviews'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1F5F5)),
        ),
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter.$1;
            return GestureDetector(
              onTap: () => setState(() => selectedFilter = filter.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF309CA3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Where a notification's button goes, if anywhere.
  (String, String)? _action(DoctorNotification n) => switch (n.kind) {
        NotificationKind.appointment || NotificationKind.payment =>
          ('View appointments', AppRoutes.doctorAppointments),
        NotificationKind.prescription => ('View prescriptions', AppRoutes.doctorPrescriptions),
        _ => null,
      };

  Widget _buildNotificationCard(DoctorNotification notification) {
    final typeColor = _typeColor(notification.kind);
    final isExpanded = expandedNotificationId == notification.id;
    final action = _action(notification);

    return GestureDetector(
      onTap: () {
        setState(() => expandedNotificationId = isExpanded ? null : notification.id);
        if (!isExpanded && !notification.isRead) _setRead(notification, true);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: notification.isRead ? AppTheme.divider : typeColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: notification.isRead
              ? []
              : [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(_typeIcon(notification.kind), color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: 'Notification options',
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNotification(notification);
                      } else if (value == 'toggle') {
                        _setRead(notification, !notification.isRead);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(notification.isRead ? Icons.mail_outline : Icons.mail, size: 18),
                            const SizedBox(width: 8),
                            Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),

              // ── Timestamp & Action ─────────────────────────────────────
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (action != null)
                    TextButton(
                      onPressed: () => context.go(action.$2),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF309CA3),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        action.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtering = selectedFilter != 'all';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            filtering ? 'Nothing here' : 'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            filtering
                ? 'No notifications match this filter.'
                : "You'll be told here when a patient books, cancels or moves an "
                    'appointment, when a pharmacy dispenses your script, and when '
                    'you get a review.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text('Could not load your notifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      ),
    );
  }

  Color _typeColor(NotificationKind kind) => switch (kind) {
        NotificationKind.review => AppTheme.warning,
        NotificationKind.payment => AppTheme.secondary,
        _ => AppTheme.primary,
      };

  IconData _typeIcon(NotificationKind kind) => switch (kind) {
        NotificationKind.appointment => Icons.calendar_today,
        NotificationKind.payment => Icons.payments_outlined,
        NotificationKind.prescription => Icons.medication,
        NotificationKind.review => Icons.star_rounded,
        NotificationKind.other => Icons.info,
      };

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }
}

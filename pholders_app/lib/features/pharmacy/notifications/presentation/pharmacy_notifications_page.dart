import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';

/// Notification model to represent a single notification.
class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final String? actionRoute;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.actionRoute,
  });
}

/// Types of notifications with corresponding colors.
enum NotificationType {
  info,
  success,
  warning,
  error,
  order,
  prescription,
  inventory,
}

/// Pharmacy Notifications Page ΓÇö displays all pharmacy notifications in an organized list.
///
/// Features:
/// - Notification list with different types (info, success, warning, error, order, prescription, inventory)
/// - Filter by notification type
/// - Mark as read/unread
/// - Delete notifications
/// - Responsive design matching the app theme
class PharmacyNotificationsPage extends StatefulWidget {
  const PharmacyNotificationsPage({super.key});

  @override
  State<PharmacyNotificationsPage> createState() => _PharmacyNotificationsPageState();
}

class _PharmacyNotificationsPageState extends State<PharmacyNotificationsPage> {
  late List<Notification> notifications;
  String? selectedFilter = 'all';
  String? expandedNotificationId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    notifications = [
      Notification(
        id: '1',
        title: 'New Prescription Order',
        message: 'Prescription order from Dr. Smith received for patient John Doe.',
        type: NotificationType.prescription,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        actionLabel: 'View',
        actionRoute: '/pharmacy/prescriptions',
      ),
      Notification(
        id: '2',
        title: 'Low Inventory Alert',
        message: 'Paracetamol 500mg stock is below minimum threshold. Please reorder.',
        type: NotificationType.inventory,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        actionLabel: 'Reorder',
        actionRoute: '/pharmacy/inventory',
      ),
      Notification(
        id: '3',
        title: 'Order Delivered',
        message: 'Medicine order #ORD-2024-5432 has been successfully delivered.',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      Notification(
        id: '4',
        title: 'Payment Received',
        message: 'Payment of R2,450.00 received from Medical Aid provider. Order settled.',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        isRead: true,
        actionLabel: 'View Invoice',
        actionRoute: '/pharmacy/billing',
      ),
      Notification(
        id: '5',
        title: 'Dispensing Queue Alert',
        message: '5 prescriptions pending in your dispensing queue. Please review.',
        type: NotificationType.info,
        timestamp: DateTime.now().subtract(const Duration(hours: 18)),
        isRead: false,
        actionLabel: 'Review',
        actionRoute: '/pharmacy/dispensing-queue',
      ),
      Notification(
        id: '6',
        title: 'Counterfeit Medicine Alert',
        message: 'System detected potential counterfeit medication batch. DO NOT DISPENSE.',
        type: NotificationType.error,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        actionLabel: 'Report',
        actionRoute: '/pharmacy/inventory',
      ),
      Notification(
        id: '7',
        title: 'System Maintenance',
        message: 'Scheduled maintenance on Saturday 2:00 AM - 4:00 AM. System will be unavailable.',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  List<Notification> get filteredNotifications {
    if (selectedFilter == 'all') return notifications;
    if (selectedFilter == 'unread') return notifications.where((n) => !n.isRead).toList();
    return notifications.where((n) => n.type.toString().split('.').last == selectedFilter).toList();
  }

  void _toggleReadStatus(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      setState(() {
        notifications[index] = Notification(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          type: notifications[index].type,
          timestamp: notifications[index].timestamp,
          isRead: !notifications[index].isRead,
          actionLabel: notifications[index].actionLabel,
          actionRoute: notifications[index].actionRoute,
        );
      });
    }
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications
          .map((n) => Notification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            timestamp: n.timestamp,
            isRead: true,
            actionLabel: n.actionLabel,
            actionRoute: n.actionRoute,
          ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ΓöÇΓöÇ Scrollable content ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 220), // Space for fixed header
                    
                    // ΓöÇΓöÇ Notifications List ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
                    if (filteredNotifications.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: List.generate(
                          filteredNotifications.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNotificationCard(
                              filteredNotifications[index],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ΓöÇΓöÇ Fixed Header ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                                '${notifications.where((n) => !n.isRead).length} unread',
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
                        if (notifications.any((n) => !n.isRead))
                          GestureDetector(
                            onTap: _markAllAsRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD1F5F5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.done_all_rounded, color: Color(0xFF309CA3), size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mark all read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF309CA3),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.pharmacySettingsNotifications),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD1F5F5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.settings_rounded, color: Color(0xFF309CA3), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Manage Settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF309CA3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('order', 'Orders'),
      ('prescription', 'Prescriptions'),
      ('inventory', 'Inventory'),
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

  Widget _buildNotificationCard(Notification notification) {
    final typeColor = _getNotificationTypeColor(notification.type);
    final typeIcon = _getNotificationTypeIcon(notification.type);
    final isExpanded = expandedNotificationId == notification.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedNotificationId = isExpanded ? null : notification.id;
          if (!isExpanded && !notification.isRead) {
            _toggleReadStatus(notification.id);
          }
        });
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: notification.isRead ? AppTheme.divider : typeColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: notification.isRead
            ? []
            : [
                BoxShadow(
                  color: typeColor.withOpacity(0.1),
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
            // ΓöÇΓöÇ Title Row ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Message
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
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
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

                // Delete button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteNotification(notification.id);
                    } else if (value == 'toggle') {
                      _toggleReadStatus(notification.id);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            notification.isRead ? Icons.mail_outline : Icons.mail,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: const Row(
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

            // ΓöÇΓöÇ Timestamp & Actions ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (notification.actionLabel != null && notification.actionRoute != null)
                  TextButton(
                    onPressed: () {
                      context.go(notification.actionRoute!);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF309CA3),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      notification.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! New notifications will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppTheme.secondary;
      case NotificationType.warning:
        return AppTheme.warning;
      case NotificationType.error:
        return AppTheme.error;
      case NotificationType.prescription:
        return AppTheme.primary;
      case NotificationType.order:
        return AppTheme.secondary;
      case NotificationType.inventory:
        return AppTheme.warning;
      case NotificationType.info:
      default:
        return AppTheme.primary;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.prescription:
        return Icons.medication;
      case NotificationType.order:
        return Icons.shopping_cart;
      case NotificationType.inventory:
        return Icons.inventory_2;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

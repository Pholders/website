import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';

/// What a notification is about. Anything the backend adds later reads as
/// [other] rather than breaking the list.
enum NotificationKind { appointment, payment, prescription, review, other }

NotificationKind _kindFrom(Object? value) => switch (value?.toString()) {
      'appointment' => NotificationKind.appointment,
      'payment' => NotificationKind.payment,
      'prescription' => NotificationKind.prescription,
      'review' => NotificationKind.review,
      _ => NotificationKind.other,
    };

/// One row of the doctor's inbox, from /users/doctor/notifications.
class DoctorNotification {
  const DoctorNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.data = const {},
  });

  factory DoctorNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return DoctorNotification(
      id: int.tryParse('${json['id']}') ?? 0,
      kind: _kindFrom(json['type']),
      title: json['title']?.toString() ?? '',
      message: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
      isRead: json['is_read'] == true,
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  final int id;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Ids the notification points at, such as appointmentId.
  final Map<String, dynamic> data;

  DoctorNotification copyWith({bool? isRead}) => DoctorNotification(
        id: id,
        kind: kind,
        title: title,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        data: data,
      );
}

/// The signed-in doctor's notifications.
///
/// [unread] is shared so the bell in the top bar and the page agree: the page
/// updates it as the doctor reads, and the bell listens.
class DoctorNotificationsRepository {
  DoctorNotificationsRepository(this._api);

  final ApiClient _api;

  final ValueNotifier<int> unread = ValueNotifier(0);

  // ApiClient hands back the response's `data` object itself.
  Future<List<DoctorNotification>> fetch({int limit = 100}) async {
    final data = await _api.get(
      '/users/doctor/notifications',
      queryParameters: {'limit': limit},
    );
    unread.value = int.tryParse('${data['unreadCount']}') ?? 0;
    final rows = data['notifications'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => DoctorNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Only the count, for the bell.
  Future<void> refreshUnread() async {
    final data = await _api.get(
      '/users/doctor/notifications',
      queryParameters: {'limit': 1},
    );
    unread.value = int.tryParse('${data['unreadCount']}') ?? 0;
  }

  Future<void> setRead(int id, {required bool read}) =>
      _api.patch('/users/doctor/notifications/$id/read', body: {'read': read});

  Future<void> markAllRead() =>
      _api.patch('/users/doctor/notifications/read-all');

  Future<void> delete(int id) =>
      _api.delete('/users/doctor/notifications/$id');
}

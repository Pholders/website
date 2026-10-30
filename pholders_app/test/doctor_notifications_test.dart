import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/notifications/data/doctor_notifications_repository.dart';
import 'package:pholders_app/features/doctor/notifications/presentation/notifications_page.dart';

/// The doctor's notifications come from their real inbox. The page used to
/// show six invented ones, and reading or deleting changed only the screen.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.routes);

  /// "METHOD /path" → (status, body)
  final Map<String, (int, Object)> routes;
  final List<String> seen = [];
  final Map<String, Object?> bodies = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    seen.add(key);
    bodies[key] = options.data;
    final (status, body) = routes[key] ?? (404, {'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

final _now = DateTime.now().toUtc();

Map<String, Object?> _row(int id, String type, String title, String body, {bool read = false, int hoursAgo = 1}) => {
      'id': id,
      'doctor_id': 17,
      'type': type,
      'title': title,
      'body': body,
      'data': {'appointmentId': 69},
      'is_read': read,
      'created_at': _now.subtract(Duration(hours: hoursAgo)).toIso8601String(),
    };

final _inbox = {
  'success': true,
  'data': {
    'notifications': [
      _row(1, 'appointment', 'New booking to accept',
          'Naledi Khumalo booked Wed 4 Nov at 10:00 and will pay cash at the practice.'),
      _row(2, 'prescription', 'Prescription dispensed', 'RX-1 for Naledi Khumalo was dispensed.', read: true, hoursAgo: 5),
      _row(3, 'review', 'New review', 'A patient rated you 5 out of 5.', hoursAgo: 30),
    ],
    'unreadCount': 2,
  },
};

const _ok = (200, {'success': true, 'data': <String, Object>{}});

void main() {
  late _Server server;
  late DoctorNotificationsRepository repo;

  Future<void> show(WidgetTester tester, Map<String, (int, Object)> routes) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server = _Server(routes);
    repo = DoctorNotificationsRepository(
        ApiClient(tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = server));
    final router = GoRouter(initialLocation: '/doctor/notifications', routes: [
      GoRoute(
        path: '/doctor/notifications',
        builder: (_, __) => DoctorNotificationsPage(repository: repo),
      ),
      GoRoute(path: '/doctor/appointments', builder: (_, __) => const Text('Appointments page')),
      GoRoute(path: '/doctor/prescriptions', builder: (_, __) => const Text('Prescriptions page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the real inbox and unread count, none of the invented ones', (tester) async {
    await show(tester, {'GET /users/doctor/notifications': (200, _inbox)});

    expect(find.text('New booking to accept'), findsOneWidget);
    expect(find.text('Prescription dispensed'), findsOneWidget);
    expect(find.text('New review'), findsOneWidget);
    expect(find.text('2 unread'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);
    expect(repo.unread.value, 2, reason: 'the bell follows the same count');

    expect(find.text('Prescription Requested'), findsNothing);
    expect(find.text('Login Attempt'), findsNothing);
    expect(find.textContaining('John Doe'), findsNothing);
  });

  testWidgets('opening an unread one marks it read on the server', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (200, _inbox),
      'PATCH /users/doctor/notifications/1/read': _ok,
    });

    await tester.tap(find.text('New booking to accept'));
    await tester.pumpAndSettle();
    expect(server.seen, contains('PATCH /users/doctor/notifications/1/read'));
    expect(server.bodies['PATCH /users/doctor/notifications/1/read'], {'read': true});
    expect(find.text('1 unread'), findsOneWidget);
    expect(repo.unread.value, 1);
  });

  testWidgets('mark all read saves, and the button goes away', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (200, _inbox),
      'PATCH /users/doctor/notifications/read-all': _ok,
    });

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(server.seen, contains('PATCH /users/doctor/notifications/read-all'));
    expect(find.text('0 unread'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('delete removes it on the server', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (200, _inbox),
      'DELETE /users/doctor/notifications/3': _ok,
    });

    await tester.tap(find.byTooltip('Notification options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(server.seen, contains('DELETE /users/doctor/notifications/3'));
    expect(find.text('New review'), findsNothing);
  });

  testWidgets('a refused change is put back and explained', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (200, _inbox),
      'DELETE /users/doctor/notifications/3': (500, {'success': false, 'message': 'Error deleting notification'}),
    });

    await tester.tap(find.byTooltip('Notification options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('New review'), findsOneWidget);
    expect(find.textContaining('Could not delete the notification'), findsOneWidget);
  });

  testWidgets('filters by kind, and a booking leads to Appointments', (tester) async {
    await show(tester, {'GET /users/doctor/notifications': (200, _inbox)});

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    expect(find.text('New review'), findsOneWidget);
    expect(find.text('New booking to accept'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View appointments'));
    await tester.pumpAndSettle();
    expect(find.text('Appointments page'), findsOneWidget);
  });

  testWidgets('an empty inbox says what will arrive here', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (200, {
        'success': true,
        'data': {'notifications': <Object>[], 'unreadCount': 0},
      }),
    });
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.textContaining('when a patient books'), findsOneWidget);
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    await show(tester, {
      'GET /users/doctor/notifications': (500, {'success': false, 'message': 'Error loading notifications'}),
    });
    expect(find.text('Could not load your notifications'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

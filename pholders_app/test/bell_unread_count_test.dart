import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/features/doctor/notifications/data/doctor_notifications_repository.dart';
import 'package:pholders_app/shared/constants/app_constants.dart';
import 'package:pholders_app/shared/widgets/app_top_navbar.dart';

/// The doctor's bell shows how many notifications are unread, and nothing
/// when none are.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());

  @override
  Future<String?> readToken() async => null;
}

class _Server implements HttpClientAdapter {
  _Server(this.unread);
  final int unread;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'notifications': <Object>[], 'unreadCount': unread},
      }),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late DoctorNotificationsRepository repo;

  Future<void> show(WidgetTester tester, int unread) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The test font draws every letter as a wide block.
      if (!details.toString().contains('overflowed')) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    repo = DoctorNotificationsRepository(ApiClient(
        tokenStorage: const _NoSession(), dio: Dio()..httpClientAdapter = _Server(unread)));
    if (sl.isRegistered<DoctorNotificationsRepository>()) {
      sl.unregister<DoctorNotificationsRepository>();
    }
    sl.registerSingleton<DoctorNotificationsRepository>(repo);
    addTearDown(() => sl.unregister<DoctorNotificationsRepository>());

    final router = GoRouter(initialLocation: '/doctor/dashboard', routes: [
      GoRoute(
        path: '/doctor/dashboard',
        builder: (_, __) => const Scaffold(
          appBar: AppTopNavbar(role: AppConstants.roleDoctor),
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('shows how many are unread', (tester) async {
    await show(tester, 3);
    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('3 unread notifications'), findsOneWidget);
  });

  testWidgets('shows nothing when all are read', (tester) async {
    await show(tester, 0);
    expect(find.text('0'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('unread notification')), findsNothing);
  });

  testWidgets('a big number is capped so the badge stays small', (tester) async {
    await show(tester, 150);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('follows the Notifications page as the doctor reads', (tester) async {
    await show(tester, 3);
    repo.unread.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.bySemanticsLabel('1 unread notification'), findsOneWidget);
    repo.unread.value = 0;
    await tester.pump();
    expect(find.text('1'), findsNothing);
  });
}

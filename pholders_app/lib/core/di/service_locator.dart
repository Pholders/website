import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../api/http_client.dart';
import '../auth/auth_actions.dart';
import '../realtime/realtime_gateway.dart';

/// Global service locator instance.
///
/// Register all dependencies here during app startup.
/// Access them anywhere via [sl<T>()].
final GetIt sl = GetIt.instance;

/// Registers all app dependencies.
///
/// Call this once in [main] before creating the Redux store. The store itself
/// is registered separately in `main.dart` after it's constructed.
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<Dio>(
    () => HttpClient.create(
      storage: sl<FlutterSecureStorage>(),
      onUnauthorized: () {
        if (sl.isRegistered<Store<AppState>>()) {
          sl<Store<AppState>>().dispatch(const SessionExpiredAction());
        }
      },
    ),
  );

  sl.registerLazySingleton<RealtimeGateway>(() => RealtimeGateway());
}

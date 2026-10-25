import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../api/http_client.dart';
import '../auth/auth_actions.dart';
import '../realtime/realtime_gateway.dart';

import '../../features/auth/data/doctor_auth_repository.dart';
import '../../features/auth/data/pharmacy_auth_repository.dart';
import '../../features/doctor/appointments/data/appointments_repository.dart';
import '../../features/doctor/prescriptions/data/prescriptions_repository.dart';
import '../../features/doctor/reviews/data/reviews_repository.dart';
import '../../features/pharmacy/dispensing_queue/data/dispensing_repository.dart';
import '../../features/pharmacy/orders/data/orders_repository.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';

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
    () => const FlutterSecureStorage(
      webOptions: WebOptions(dbName: 'pholders', publicKey: 'pholders_app'),
    ),
  );

  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(sl()));

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<TokenStorage>()),
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

  // ─── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<DoctorAuthRepository>(
    () => DoctorAuthRepository(sl<ApiClient>()),
  );

  sl.registerLazySingleton<PharmacyAuthRepository>(
    () => PharmacyAuthRepository(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AppointmentsRepository>(
    () => AppointmentsRepository(sl<ApiClient>()),
  );

  sl.registerLazySingleton<PrescriptionsRepository>(
    () => PrescriptionsRepository(sl<ApiClient>(), sl<TokenStorage>()),
  );

  sl.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepository(sl<ApiClient>()),
  );

  sl.registerLazySingleton<DispensingRepository>(
    () => DispensingRepository(sl<ApiClient>()),
  );

  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepository(sl<ApiClient>()),
  );
}

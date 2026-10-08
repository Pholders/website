import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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
/// Call this once in [main] before [runApp].
Future<void> setupServiceLocator() async {
  // ─── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      // Without this, a secure-storage write on web can be lost when the tab
      // is restored from the back/forward cache.
      webOptions: WebOptions(dbName: 'pholders', publicKey: 'pholders_app'),
    ),
  );

  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(sl()));

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<TokenStorage>()),
  );

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

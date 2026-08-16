import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../network/api_client.dart';
import '../../shared/constants/app_constants.dart';

/// Global service locator instance.
///
/// Register all dependencies here during app startup.
/// Access them anywhere via [sl<T>()].
final GetIt sl = GetIt.instance;

/// Registers all app dependencies.
///
/// Call this once in [main] before [runApp].
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<ApiClient>(() => ApiClient(
        baseUrl: AppConstants.apiBaseUrl,
      ));

  sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage());

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl<ApiClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AdminLoginUseCase>(
    () => AdminLoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyAdminOtpUseCase>(
    () => VerifyAdminOtpUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(
      apiClient: sl<ApiClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );
}

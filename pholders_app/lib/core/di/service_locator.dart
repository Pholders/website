import 'package:get_it/get_it.dart';

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
  // Example: sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  // Add repositories, services, and use cases here as features are built.
}

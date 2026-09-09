import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:redux/redux.dart';

import 'app/app_reducer.dart';
import 'app/app_state.dart';
import 'core/auth/auth_actions.dart';
import 'core/auth/auth_middleware.dart';
import 'core/auth/token_storage.dart';
import 'core/di/service_locator.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'features/auth/data/doctor_auth_repository.dart';
import 'features/doctor/appointments/data/appointments_repository.dart';
import 'features/doctor/appointments/redux/appointments_middleware.dart';
import 'features/doctor/prescriptions/data/prescriptions_repository.dart';
import 'features/doctor/prescriptions/redux/prescriptions_middleware.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs (e.g. /doctor/appointments instead of /#/doctor/appointments)
  usePathUrlStrategy();

  // 1. Set up dependency injection
  await setupServiceLocator();

  // 2. Create the Redux store with the root reducer, initial state and the
  //    middleware that performs all authentication side effects.
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [
      ...createAuthMiddleware(
        doctorAuth: sl<DoctorAuthRepository>(),
        tokenStorage: sl<TokenStorage>(),
      ),
      ...createAppointmentsMiddleware(
        repository: sl<AppointmentsRepository>(),
      ),
      ...createPrescriptionsMiddleware(
        repository: sl<PrescriptionsRepository>(),
      ),
    ],
  );

  // 3. Any 401/403 from the API means the JWT is gone or expired — drop the
  //    session so the router sends the user back to sign in.
  sl<ApiClient>().onUnauthorized =
      () => store.dispatch(const SessionExpiredAction());

  // 4. Restore a previously stored session before the first frame is shown.
  store.dispatch(const AppStartedAction());

  runApp(PholdersApp(store: store));
}

/// Root widget of the PHolders application.
///
/// Provides the Redux [Store] to the entire widget tree via [StoreProvider],
/// and configures the [MaterialApp.router] with GoRouter.
class PholdersApp extends StatefulWidget {

  const PholdersApp({super.key, required this.store});
  final Store<AppState> store;

  @override
  State<PholdersApp> createState() => _PholdersAppState();
}

class _PholdersAppState extends State<PholdersApp> {
  late final _router = createRouter(widget.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: widget.store,
      child: MaterialApp.router(
        title: 'PHolders',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

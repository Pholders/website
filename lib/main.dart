import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'screens/patients_screen.dart';
 
void main() {
  runApp(const DoctorApp());
=======
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:redux/redux.dart';

import 'app/app_reducer.dart';
import 'app/app_state.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/auth/auth_middleware.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs (e.g. /doctor/appointments instead of /#/doctor/appointments)
  usePathUrlStrategy();

  // 1. Set up dependency injection
  await setupServiceLocator();

  // 2. Create the Redux store with the root reducer and initial state
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [
      // Development auth middleware to simulate login behavior
      ...createAuthMiddleware(),
    ],
  );

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
>>>>>>> ebd9ff0d2f046df1133b3b423dcea86c51611aca
}
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:redux/redux.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'store/app_state.dart';
import 'store/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs (e.g. /doctor/appointments instead of /#/doctor/appointments)
  usePathUrlStrategy();

  // 1. Set up dependency injection
  await setupServiceLocator();

  // 2. Create the Redux store with the root reducer, middleware, and initial state
  final store = createAppStore();

  runApp(PholdersApp(store: store));
}

/// Root widget of the PHolders application.
///
/// Provides the Redux [Store] to the entire widget tree via [StoreProvider],
/// and configures the [MaterialApp.router] with GoRouter.
class PholdersApp extends StatefulWidget {
  final Store<AppState> store;

  const PholdersApp({super.key, required this.store});

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

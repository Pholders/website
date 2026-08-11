import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../routing/app_routes.dart';
import 'auth_actions.dart';

/// Signs the current user out and returns them to the login page.
///
/// Dispatching clears the store and, via middleware, revokes the server
/// session and wipes secure storage. The router reads auth state but does not
/// listen to the store, so the redirect has to be made explicitly here.
void performLogout(BuildContext context) {
  StoreProvider.of<AppState>(context).dispatch(const LogoutAction());
  context.go(AppRoutes.login);
}

import 'package:redux/redux.dart';

import '../core/auth/auth_actions.dart';
import 'app_state.dart';
import 'middleware/auth_middleware.dart';
import 'reducers/app_reducer.dart';

Store<AppState> createAppStore() {
  final authMiddleware = AuthMiddleware();
  final store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: authMiddleware.middleware,
  );

  store.dispatch(const RestoreSessionAction(token: '', role: '', userName: ''));

  return store;
}

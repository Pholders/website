import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../di/service_locator.dart';
import 'auth_actions.dart';
import 'auth_middleware.dart' show inactivityLimit;
import 'token_storage.dart';

/// Signs a doctor out after [limit] without touching the app (30 minutes,
/// agreed with the team on 2026-11-24), so an open session on a shared
/// practice computer cannot be used by whoever sits down next.
///
/// Any click, mouse movement, scroll or key press counts as activity. The
/// time is also written to storage (at most once a minute), which does two
/// things: a tab reopened after the limit is signed out at start-up (see
/// the auth middleware), and an idle second tab does not sign out a doctor
/// who is busy in another one.
class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.store,
    required this.child,
    this.storage,
    this.limit = inactivityLimit,
    this.checkEvery = const Duration(seconds: 30),
    this.clock = DateTime.now,
  });

  final Store<AppState> store;
  final Widget child;

  /// Defaults to the app's own.
  final TokenStorage? storage;
  final Duration limit;
  final Duration checkEvery;

  /// Injected by tests.
  final DateTime Function() clock;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  late DateTime _lastActive;
  DateTime? _lastSaved;
  Timer? _timer;

  TokenStorage? get _storage =>
      widget.storage ??
      (sl.isRegistered<TokenStorage>() ? sl<TokenStorage>() : null);

  @override
  void initState() {
    super.initState();
    // Set here, not lazily: a lazy field would start the clock at the first
    // check instead of now.
    _lastActive = widget.clock();
    _timer = Timer.periodic(widget.checkEvery, (_) => _check());
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent _) {
    _touch();
    return false; // never swallow the key
  }

  bool get _watching {
    final auth = widget.store.state.authState;
    return auth.isAuthenticated && auth.isDoctor && !auth.isSigningOut;
  }

  void _touch() {
    final now = widget.clock();
    _lastActive = now;
    if (!_watching) return;
    final saved = _lastSaved;
    if (saved == null || now.difference(saved) >= const Duration(minutes: 1)) {
      _lastSaved = now;
      _storage?.saveLastActive(now);
    }
  }

  Future<void> _check() async {
    final now = widget.clock();
    if (!_watching) {
      // Not a signed-in doctor: start the clock afresh for the next sign-in.
      _lastActive = now;
      return;
    }
    if (now.difference(_lastActive) < widget.limit) return;

    // Another tab may have been in use all along.
    final shared = await _storage?.readLastActive();
    if (shared != null && now.difference(shared) < widget.limit) {
      _lastActive = shared;
      return;
    }
    if (!mounted || !_watching) return;
    widget.store.dispatch(const InactivityLogoutAction());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _touch(),
      onPointerHover: (_) => _touch(),
      onPointerMove: (_) => _touch(),
      onPointerSignal: (_) => _touch(),
      child: widget.child,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../../features/doctor/appointments/redux/appointments_actions.dart';
import 'splash_view.dart';

/// Covers the app with the splash screen while a session gets going: while
/// a stored session is read at startup, while a login request is answered,
/// and after signing in until the first page has its data. A login that
/// fails lifts it at once, back to the form and its message.
///
/// The page builds underneath, so it fetches as usual; the splash just hides
/// the half-loaded state and fades away once the data is in.
///
/// For a doctor that data is their appointments, which the dashboard, the
/// patient list and most doctor pages are built from. A pharmacy's pages
/// fetch nothing up front, so for them the splash only covers signing in.
///
/// Signing out shows it too, from the click until the server has ended the
/// session, at most [SplashGate.signOutTimeout], landing on the login page.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.minimum = const Duration(milliseconds: 1200),
    this.timeout = const Duration(seconds: 15),
    this.signOutTimeout = const Duration(seconds: 5),
  });

  final Widget child;

  /// The least time the splash stays once a session is signed in, so a
  /// quick load does not flicker it.
  final Duration minimum;

  /// The most it waits for data. Past this the page shows whatever it has,
  /// so no one is ever stuck behind the splash.
  final Duration timeout;

  /// The most signing out waits for the server. The session on this device
  /// is gone at once, so there is nothing to protect by waiting longer.
  final Duration signOutTimeout;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showing = false;
  Timer? _giveUp;

  /// Runs for [SplashGate.minimum] from the moment the splash shows. Timed
  /// with a timer rather than the clock, so it pauses with the app.
  Timer? _minimum;
  bool _minimumMet = true;

  /// Set when the splash may go but has not shown for its minimum yet.
  bool _liftPending = false;

  /// The session the splash has been lifted for. A later reload of the same
  /// data, or a page that reloads it, does not bring the splash back.
  String? _releasedFor;

  /// True while the connector's onInit runs, inside its build.
  bool _initialising = false;

  /// The session a fetch has been started for, so it is started once.
  String? _fetchedFor;

  /// Set while a sign-out is covered, so it ends with the minimum showing
  /// time rather than lifting at once as an empty startup does.
  bool _coveringSignOut = false;

  /// Set when the sign-out wait timed out, so it is not shown again until
  /// that sign-out finishes.
  bool _signOutReleased = false;

  @override
  void dispose() {
    _minimum?.cancel();
    _giveUp?.cancel();
    super.dispose();
  }

  void _update(Store<AppState> store, _Gate gate) {
    // A session the splash has not yet been shown and lifted for.
    final newSession = gate.signedIn && gate.token != _releasedFor;
    if (!gate.signingOut) _signOutReleased = false;
    final signingOut = gate.signingOut && !_signOutReleased;
    final waiting = gate.restoring ||
        gate.signingIn ||
        signingOut ||
        (newSession && gate.waitingForData);

    if (waiting) {
      _liftPending = false;
      if (!_showing) _show();
      if (signingOut) {
        _coveringSignOut = true;
        _giveUp ??= Timer(widget.signOutTimeout, () {
          _signOutReleased = true;
          _lift();
        });
      } else if (gate.token != null && _giveUp == null) {
        final token = gate.token;
        _giveUp = Timer(widget.timeout, () {
          _releasedFor = token;
          _lift();
        });
      }
      _fetchIfNobodyHas(store, gate);
      return;
    }

    // Signed in with nothing to wait for, as a pharmacy is: the splash
    // still marks the moment, for [SplashGate.minimum].
    if (newSession && !_showing) _show();

    if (!_showing || _liftPending) return;
    // No session, from startup or a login that failed: nothing to wait
    // for, and the form should be back with its message at once. A
    // sign-out still gets its minimum, so it does not flicker.
    if (!gate.signedIn && !_coveringSignOut) {
      _lift();
      return;
    }
    if (gate.signedIn) _releasedFor = gate.token;
    if (_minimumMet) {
      _lift();
    } else {
      _liftPending = true;
    }
  }

  void _show() {
    _startMinimum();
    _set(true);
  }

  void _startMinimum() {
    _minimum?.cancel();
    _minimumMet = false;
    _minimum = Timer(widget.minimum, () {
      _minimumMet = true;
      if (_liftPending) _lift();
    });
  }

  /// The dashboard asks for appointments as it builds. A doctor who lands
  /// on a page that does not would wait for nothing, so after the frame the
  /// gate asks itself if no one has.
  void _fetchIfNobodyHas(Store<AppState> store, _Gate gate) {
    if (!gate.waitingForData || gate.token == _fetchedFor) return;
    final token = gate.token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedFor == token) return;
      _fetchedFor = token;
      final now = _Gate.from(store);
      if (now.token == token && now.waitingForData && !now.fetching) {
        store.dispatch(const LoadAppointmentsAction());
      }
    });
  }

  void _lift() {
    _coveringSignOut = false;
    _liftPending = false;
    _minimum?.cancel();
    _minimumMet = true;
    _giveUp?.cancel();
    _giveUp = null;
    _set(false);
  }

  void _set(bool showing) {
    if (_showing == showing) return;
    _showing = showing;
    // From onInit the connector is mid-build and its builder, which reads
    // [_showing], has not run yet: nothing needs marking. The scheduler can
    // still say idle there (the first build after runApp or a hot restart
    // is outside any frame), so the phase check below would let setState
    // through and throw.
    if (!mounted || _initialising) return;
    // The store can notify mid-build, when setState is not allowed; then the
    // rebuild waits for the frame to finish, and a frame is asked for so
    // there is one. From a timer, outside any frame, it happens at once.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _Gate>(
      distinct: true,
      converter: _Gate.from,
      onInit: (store) {
        _initialising = true;
        try {
          final gate = _Gate.from(store);
          // At startup the splash is up from the very first frame.
          if (gate.restoring || gate.waitingForData) {
            _showing = true;
            _startMinimum();
          }
          _update(store, gate);
        } finally {
          _initialising = false;
        }
      },
      onWillChange: (_, next) =>
          _update(StoreProvider.of<AppState>(context, listen: false), next),
      builder: (context, _) => Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showing,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showing
                    ? const SplashView(key: ValueKey('splash'))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the gate reads from the store.
class _Gate {
  const _Gate({
    required this.restoring,
    required this.signingIn,
    required this.signingOut,
    required this.signedIn,
    required this.token,
    required this.waitingForData,
    required this.fetching,
  });

  factory _Gate.from(Store<AppState> store) {
    final auth = store.state.authState;
    final appointments = store.state.appointmentsState;
    final settled =
        appointments.hasLoadedOnce || appointments.errorMessage != null;
    return _Gate(
      restoring: auth.isRestoring,
      signingIn: auth.isSigningIn,
      signingOut: auth.isSigningOut,
      signedIn: auth.isAuthenticated,
      token: auth.token,
      waitingForData: auth.isAuthenticated && auth.isDoctor && !settled,
      fetching: appointments.isLoading,
    );
  }

  final bool restoring;
  final bool signingIn;
  final bool signingOut;
  final bool signedIn;
  final String? token;
  final bool waitingForData;
  final bool fetching;

  @override
  bool operator ==(Object other) =>
      other is _Gate &&
      other.restoring == restoring &&
      other.signingIn == signingIn &&
      other.signingOut == signingOut &&
      other.signedIn == signedIn &&
      other.token == token &&
      other.waitingForData == waitingForData &&
      other.fetching == fetching;

  @override
  int get hashCode => Object.hash(restoring, signingIn, signingOut, signedIn,
      token, waitingForData, fetching);
}

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/constants/landing_keys.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_hero_header.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/login_panel.dart';
import 'widgets/signup_panel.dart';

/// What the teal circle holds.
enum LandingPanel {
  /// /get-started: the doctors and the Get Started slider.
  landing,

  /// /login: the sign-in form.
  login,

  /// /register: step 1 of creating an account.
  signup;

  /// Login and signup are forms: the circle moves up to hold them and the
  /// page is held to the window, without scrolling.
  bool get isForm => this != landing;
}

/// Landing, Login and Signup — Figma "Main screen - 2", "Doctor login" and
/// "Doctor Create account 1".
///
/// The designs share the headline and the teal circle; only what sits in the
/// circle differs ([LandingPanel]). All three routes build this page under one
/// page key, so moving between them updates it in place and the circle's
/// contents animate across instead of the whole page being replaced.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key, this.panel = LandingPanel.landing});

  final LandingPanel panel;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  /// 0 = Landing, 1 = a form. Moves only when the route switches, so the
  /// circle glides between the two layouts but follows window resizes at once.
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.panel.isForm ? 1 : 0,
  );

  @override
  void didUpdateWidget(LandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.panel.isForm != oldWidget.panel.isForm) {
      _swap.animateTo(widget.panel.isForm ? 1 : 0);
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _swap.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < AppTheme.mobileBreakpoint;
    final panel = widget.panel;

    // Login offers Signup; Landing and Signup offer Login.
    final toSignup = panel == LandingPanel.login;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Scrollable body ──────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            // The forms are laid out to fit the window and must not scroll.
            // Phones keep scrolling so the on-screen keyboard cannot hide the
            // fields.
            physics: panel.isForm && !isMobile
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 120),
                isMobile
                    ? _MobileContent(panel: panel)
                    : _DesktopHero(
                        screenSize: size,
                        panel: panel,
                        swap: _swap,
                      ),
                SizedBox(key: LandingKeys.features, height: 0),
                SizedBox(key: LandingKeys.about, height: 0),
                SizedBox(key: LandingKeys.services, height: 0),
                SizedBox(key: LandingKeys.howItWorks, height: 0),
                SizedBox(key: LandingKeys.support, height: 0),
              ],
            ),
          ),

          // ── Fixed top navbar ─────────────────────────────────────────────────
          Positioned(
            top: 36,
            left: isMobile ? 16 : 80,
            right: isMobile ? 16 : 80,
            child: PublicNavbar(
              actionLabel: toSignup ? 'Signup' : 'Login',
              actionRoute: toSignup ? AppRoutes.register : AppRoutes.login,
              onNavLinkTap: _scrollTo,
            ),
          ),
        ],
      ),
    );
  }
}

/// How the circle's contents cross over when the panel changes.
const Duration _swapDuration = Duration(milliseconds: 350);

Widget _swapTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  );
}

Widget _swapLayout(Widget? current, List<Widget> previous) {
  return Stack(
    alignment: Alignment.topCenter,
    children: [...previous, if (current != null) current],
  );
}

// ─── Desktop hero ─────────────────────────────────────────────────────────────

/// Laid out on the 1440 × 1024 Figma frames and scaled to fit the viewport, so
/// the teal circle is always cut off by the bottom edge, as in the designs.
///
/// The headline scales with the window. The forms keep their design size and
/// only shrink when the window is too short for them, as the forms never
/// scroll.
class _DesktopHero extends StatelessWidget {
  const _DesktopHero({
    required this.screenSize,
    required this.panel,
    required this.swap,
  });
  final Size screenSize;
  final LandingPanel panel;

  /// 0 = Landing, 1 = a form; places the circle between the two layouts.
  final Animation<double> swap;

  // Figma frame below the 120px navbar spacer.
  static const double _frameWidth = 1440;
  static const double _frameHeight = 904;

  // Space above and below the headline.
  static const double _headerTop = 50;
  static const double _headerGap = 20;

  // Circle and art, measured from the top of the area below the headline.
  static const double _circleDiameter = 924;
  static const double _landingCircleTop = 77;
  static const double _formCircleTop = 25;
  static const double _doctorsWidth = 470;
  static const double _buttonTop = 463;

  /// The forms are not scaled, so their circle never shrinks below this.
  static const double _formMinDiameter = 640;

  @override
  Widget build(BuildContext context) {
    final s = math
        .min(
          screenSize.width / _frameWidth,
          (screenSize.height - 120) / _frameHeight,
        )
        .clamp(0.6, 1.25)
        .toDouble();
    // The forms are held to the window exactly; Landing may run taller only
    // on a window too short for the smallest scale.
    final heroHeight = panel.isForm
        ? screenSize.height - 120
        : math.max(screenSize.height - 120, _frameHeight * s);
    final headerBlock =
        (_headerTop + PublicHeroHeader.designHeight + _headerGap) * s;
    final circleArea = heroHeight - headerBlock;

    final width = screenSize.width;
    final landingDiameter = _circleDiameter * s;
    final formDiameter = math.min(
      math.max(_circleDiameter * s, _formMinDiameter),
      width - 32,
    );

    return Column(
      children: [
        SizedBox(height: _headerTop * s),
        PublicHeroHeader(scale: s),
        SizedBox(height: _headerGap * s),
        // Fills to the bottom of the window, so the circle is cut by it.
        SizedBox(
          height: circleArea,
          child: SizedBox(
            width: width,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // The circle glides between its Landing and form positions.
                AnimatedBuilder(
                  animation: swap,
                  builder: (context, child) {
                    final t = Curves.easeInOutCubic.transform(swap.value);
                    final diameter =
                        lerpDouble(landingDiameter, formDiameter, t)!;
                    return Positioned(
                      top:
                          lerpDouble(_landingCircleTop, _formCircleTop, t)! * s,
                      left: (width - diameter) / 2,
                      width: diameter,
                      height: diameter,
                      child: child!,
                    );
                  },
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.landingTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: _swapDuration,
                  transitionBuilder: _swapTransition,
                  layoutBuilder: _swapLayout,
                  child: switch (panel) {
                    LandingPanel.landing => SizedBox(
                        key: const ValueKey(LandingPanel.landing),
                        width: _circleDiameter * s,
                        height: circleArea,
                        child: Stack(
                          children: [
                            // Doctors, with Get Started across their legs.
                            Positioned(
                              top: 0,
                              left: (_circleDiameter - _doctorsWidth) / 2 * s,
                              width: _doctorsWidth * s,
                              child: Image.asset(
                                'assets/doctors.png',
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                            Positioned(
                              top: _buttonTop * s,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _GetStartedButton(scale: s),
                              ),
                            ),
                          ],
                        ),
                      ),
                    LandingPanel.login => _formInCircle(
                        LandingPanel.login,
                        const LoginPanel(fieldWidth: 350),
                        diameter: formDiameter,
                        height: circleArea,
                        scale: s,
                      ),
                    LandingPanel.signup => _formInCircle(
                        LandingPanel.signup,
                        const SignupPanel(),
                        diameter: formDiameter,
                        height: circleArea,
                        scale: s,
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// A form laid out in the circle, as wide as it (so the login form's
  /// full-width rule ends at its edges) and shrunk to fit when the window is
  /// too short, since the page does not scroll.
  static Widget _formInCircle(
    LandingPanel panel,
    Widget form, {
    required double diameter,
    required double height,
    required double scale,
  }) {
    return Container(
      key: ValueKey(panel),
      width: diameter,
      height: height,
      padding: EdgeInsets.only(top: _formCircleTop * scale, bottom: 16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(width: diameter, child: form),
      ),
    );
  }
}

// ─── Mobile ───────────────────────────────────────────────────────────────────

/// On phones: the stacked hero, or a form in a teal card.
class _MobileContent extends StatelessWidget {
  const _MobileContent({required this.panel});
  final LandingPanel panel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _swapDuration,
      transitionBuilder: _swapTransition,
      layoutBuilder: _swapLayout,
      child: switch (panel) {
        LandingPanel.landing =>
          const _MobileHero(key: ValueKey(LandingPanel.landing)),
        LandingPanel.login => const _MobileCard(
            key: ValueKey(LandingPanel.login),
            child: LoginPanel(fieldWidth: double.infinity),
          ),
        LandingPanel.signup => const _MobileCard(
            key: ValueKey(LandingPanel.signup),
            child: SignupPanel(compact: true),
          ),
      },
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: AppTheme.landingTeal,
          borderRadius: BorderRadius.circular(32),
        ),
        child: child,
      ),
    );
  }
}

// ─── Mobile hero ──────────────────────────────────────────────────────────────

class _MobileHero extends StatelessWidget {
  const _MobileHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Headline
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'A '),
                TextSpan(
                  text: 'Smarter',
                  style: TextStyle(color: AppTheme.landingTeal),
                ),
                TextSpan(text: ' Way to\nManage Patients'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Access patient records, create secure digital prescriptions, and monitor health updates all in one platform.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Doctors over the teal circle, Get Started across their legs.
          SizedBox(
            width: 320,
            height: 360,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 50,
                    left: 0,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: const BoxDecoration(
                        color: AppTheme.landingTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 60,
                    width: 200,
                    child: Image.asset(
                      'assets/doctors.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  const Positioned(
                    top: 196,
                    left: 0,
                    right: 0,
                    child: Center(child: _GetStartedButton(scale: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Get Started button ───────────────────────────────────────────────────────

/// Slide-to-start: a solid aqua pill inside a wider translucent track that
/// ends in an arrow. Dragging the pill to the end opens Login; letting go
/// early springs it back. A tap plays the same slide, so a click still works.
/// Designed at 365 × 58; [scale] resizes it with the hero.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({this.scale = 1});
  final double scale;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with SingleTickerProviderStateMixin {
  /// 0 = pill at the start of the track, 1 = pill at the end.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// Past this fraction of the track, letting go completes the slide.
  static const double _completeAt = 0.6;

  bool _completing = false;

  double get _trackWidth => 365 * widget.scale;
  double get _pillWidth => 180 * widget.scale;
  // Less the track's 1px border on each side, so the pill stops inside it.
  double get _travel => _trackWidth - _pillWidth - 2;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_completing) return;
    _slide.value += details.primaryDelta! / _travel;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_completing) return;
    final flung = details.primaryVelocity! > 800;
    if (flung || _slide.value >= _completeAt) {
      _complete();
    } else {
      _slide.animateBack(0, curve: Curves.easeOutBack);
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    await _slide.animateTo(1, curve: Curves.easeOut);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final height = 58 * scale;
    final radius = BorderRadius.circular(height / 2);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _complete,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Container(
          width: _trackWidth,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              final t = _slide.value;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Arrow fades as the pill reaches it.
                  Positioned(
                    right: 22 * scale,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Icon(
                        Icons.east,
                        color: Colors.white,
                        size: 30 * scale,
                      ),
                    ),
                  ),
                  Positioned(
                    left: t * _travel,
                    child: Container(
                      width: _pillWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.landingAqua,
                        borderRadius: radius,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

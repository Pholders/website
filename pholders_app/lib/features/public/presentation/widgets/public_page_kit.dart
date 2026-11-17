import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/hide_on_scroll_header.dart';
import '../../../../shared/widgets/public_navbar.dart';

/// The pieces the public pages (Features, About, …) are built from, so they
/// share one look: the colours and gradient, the fade-in, the hero backdrop,
/// section titles, pill buttons, the closing call to action and the footer,
/// and [PublicPageFrame], which lays a page out under the fixed navbar.

/// A public page: its [children] in a scrolling column under the fixed
/// navbar. Wrap a section in [PublicContentWidth] to hold it to the content
/// width; leave it bare to span the window, as a coloured band does.
class PublicPageFrame extends StatelessWidget {
  const PublicPageFrame({super.key, required this.children});

  final List<Widget> children;

  static double gutterFor(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint
          ? 16.0
          : 80.0;

  @override
  Widget build(BuildContext context) {
    final gutter = gutterFor(context);
    return Scaffold(
      backgroundColor: Colors.white,
      // The navbar slides away on the way down the page and back on the
      // way up.
      body: HideOnScrollHeader(
        top: 36,
        left: gutter,
        right: gutter,
        header: const PublicNavbar(
          actionLabel: 'Login',
          actionRoute: AppRoutes.login,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Holds [child] to the content width, with the page gutter.
class PublicContentWidth extends StatelessWidget {
  const PublicContentWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = PublicPageFrame.gutterFor(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200 + gutter * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: child,
        ),
      ),
    );
  }
}

/// Space between sections: more on a wide screen.
class PublicGap extends StatelessWidget {
  const PublicGap({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
      height: MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint
          ? 72
          : 120);
}

// ─── Look ─────────────────────────────────────────────────────────────────────

/// The colours of the public pages.
abstract final class PublicColors {
  static const teal = AppTheme.landingTeal;
  static const aqua = AppTheme.landingAqua;
  static const deep = Color(0xFF0E2B2E);
  static const ink = Color(0xFF0F1A1B);
  static const body = Color(0xFF55636A);
  static const hairline = Color(0xFFE6EEEF);
}

const publicBrandGradient = LinearGradient(
  colors: [Color(0xFF1F8A92), Color(0xFF4CC3CC), Color(0xFF8FE0E6)],
);

// ─── Motion ───────────────────────────────────────────────────────────────────

/// Fades and lifts its child in once, when it is first built.
class Reveal extends StatelessWidget {
  const Reveal({required this.child, this.delay = 0});
  final Widget child;

  /// A share of the animation spent waiting, for staggering.
  final double delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Text painted with the brand gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {required this.style, this.align});
  final String text;
  final TextStyle style;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => publicBrandGradient.createShader(bounds),
      child: Text(text, textAlign: align, style: style),
    );
  }
}

/// Soft glows and a faint dot grid behind the hero.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget glow(Color c, double size) => IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0)],
              ),
            ),
          ),
        );
    return ClipRect(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          Positioned(
              top: -160, right: -120, child: glow(PublicColors.aqua, 620)),
          Positioned(
              bottom: -220, left: -180, child: glow(PublicColors.teal, 560)),
          child,
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = const Color(0xFF309CA3).withValues(alpha: 0.10);
    const step = 28.0;
    for (var y = step / 2; y < size.height; y += step) {
      // Fades out towards the bottom, into the white below.
      final fade = (1 - y / size.height).clamp(0.0, 1.0);
      dot.color = const Color(0xFF309CA3).withValues(alpha: 0.12 * fade);
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PillButton extends StatefulWidget {
  const PillButton(
      {required this.label, required this.onTap, this.dark = false});
  final String label;
  final VoidCallback onTap;
  final bool dark;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: dark ? PublicColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: dark
                ? null
                : Border.all(color: PublicColors.hairline, width: 1.5),
            boxShadow: [
              if (dark || _hover)
                BoxShadow(
                  color: (dark ? PublicColors.ink : PublicColors.teal)
                      .withValues(alpha: _hover ? 0.25 : 0.15),
                  blurRadius: _hover ? 24 : 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : PublicColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: Offset(_hover ? 0.2 : 0, 0),
                child: Icon(
                  dark ? Icons.arrow_forward_rounded : Icons.south_rounded,
                  size: 18,
                  color: dark ? PublicColors.aqua : PublicColors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.eyebrow,
    required this.title,
    this.light = false,
  });
  final String eyebrow;
  final String title;

  /// On the dark section.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    return Column(
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: light ? PublicColors.aqua : PublicColors.teal,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: small ? 30 : 44,
              fontWeight: FontWeight.w700,
              letterSpacing: small ? -0.5 : -1.2,
              height: 1.15,
              color: light ? Colors.white : PublicColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Call to action ───────────────────────────────────────────────────────────

class PublicCallToAction extends StatelessWidget {
  const PublicCallToAction();

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;

    Widget ring(double size) => IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 1.5),
            ),
          ),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F8A92), Color(0xFF3FB3BC), Color(0xFF6DD0D8)],
        ),
        boxShadow: [
          BoxShadow(
            color: PublicColors.teal.withValues(alpha: 0.3),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -90, top: -90, child: ring(300)),
          Positioned(right: -30, top: -30, child: ring(180)),
          Positioned(left: -70, bottom: -110, child: ring(260)),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 64, vertical: isMobile ? 44 : 72),
            child: Column(
              children: [
                Text(
                  'Ready to see it for yourself?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 30 : 46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isMobile ? -0.5 : -1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Doctors and pharmacies sign up here. Patients use the '
                  'PHolders app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17, height: 1.5, color: Color(0xFFE9FAFB)),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.register),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: PublicColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Create an account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Login',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PublicFooter extends StatelessWidget {
  const PublicFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: PublicColors.hairline),
        const SizedBox(height: 22),
        Text(
          '© ${DateTime.now().year} PHolders',
          style: const TextStyle(fontSize: 13, color: PublicColors.body),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/constants/landing_keys.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

/// Landing / "Get Started" screen — Figma "Main screen - 2".
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < AppTheme.mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable body ──────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 120),
                isMobile
                    ? const _MobileHero()
                    : _DesktopHero(screenSize: size),
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
              actionLabel: 'Login',
              actionRoute: AppRoutes.login,
              onNavLinkTap: _scrollTo,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Desktop hero ─────────────────────────────────────────────────────────────

class _DesktopHero extends StatelessWidget {
  const _DesktopHero({required this.screenSize});
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    // Available height after navbar spacer
    final availableHeight = screenSize.height - 120;

    return SizedBox(
      height: availableHeight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: availableHeight * 0.02),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Headline — larger
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: 'A '),
                    TextSpan(
                      text: 'Smarter',
                      style: TextStyle(
                        color: Color(0xFF309CA3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(text: ' Way to Manage\nPatients'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quote icon + subtitle
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/icons/inverted-commas-icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      letterSpacing: 0.3,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              SizedBox(height: availableHeight * 0.02),

              // Doctors image with teal semicircle + Get Started inside
              SizedBox(
                width: 480,
                height: availableHeight * 0.62,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Teal semicircle — larger
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: availableHeight * 0.46,
                        decoration: const BoxDecoration(
                          color: Color(0xFF309CA3),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(240),
                            topRight: Radius.circular(240),
                          ),
                        ),
                      ),
                    ),
                    // Doctors image — larger, pushed up above button
                    Positioned(
                      bottom: 70,
                      child: Image.asset(
                        'assets/icons/doctors.png',
                        height: availableHeight * 0.54,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Get Started button — below the knees of the doctors image
                    Positioned(
                      bottom: availableHeight * 0.15,
                      child: const _GetStartedButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile hero ──────────────────────────────────────────────────────────────

class _MobileHero extends StatelessWidget {
  const _MobileHero();

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
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.3,
              ),
              children: [
                TextSpan(text: 'A '),
                TextSpan(
                  text: 'Smarter',
                  style: TextStyle(
                    color: Color(0xFF309CA3),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(text: ' Way to\nManage Patients'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Access patient records, create secure digital prescriptions, and monitor health updates all in one platform.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
          ),
          const SizedBox(height: 24),

          // Doctors image with teal semicircle + button inside
          SizedBox(
            width: 280,
            height: 260,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFF309CA3),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(140),
                        topRight: Radius.circular(140),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 52,
                  child: Image.asset(
                    'assets/icons/doctors.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const Positioned(
                  bottom: 10,
                  child: _GetStartedButton(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Get Started button ───────────────────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.register),
      // Outer container — light teal background spans across both
      child: Container(
        width: 230,
        height: 44,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF6DD0D8).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF6DD0D8).withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Solid teal "Get Started" pill inside
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF6DD0D8),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/splash_view.dart';

/// Splash screen — "Main screen - 1" from Figma.
///
/// Shows the PHolders logo and tagline for 2 seconds,
/// then automatically navigates to the landing page.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for the logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Auto-navigate to landing after 2.5 seconds (only if user is on splash)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && GoRouterState.of(context).matchedLocation == '/') {
        context.go(AppRoutes.landing);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(opacity: _fadeIn, child: const SplashView()),
    );
  }
}

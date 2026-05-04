import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';

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

    // Auto-navigate to landing after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) context.go(AppRoutes.landing);
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
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PHolders logo
              Image.asset(
                'assets/PHolders-icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // Brand name
              const Text(
                'PHOLDERS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF309CA3),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'HEALTHCARE THAT WORKS FOR YOU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF181C),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6DD0D8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// The splash screen's content: logo, name, tagline and a spinner, on white.
///
/// Shown by [SplashPage] at "/", and by [SplashGate] as the loader while a
/// signed-in session fetches what its first page needs.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/PHolders-icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
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
    );
  }
}

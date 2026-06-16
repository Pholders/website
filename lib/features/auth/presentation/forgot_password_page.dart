import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

/// Forgot password screen matching Figma design.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final semiCircleHeight = size.height * 0.58;
    final semiCircleWidth = size.width * 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            // ── Navbar ────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 60, right: 60),
              child: PublicNavbar(
                actionLabel: 'Login',
                actionRoute: AppRoutes.login,
              ),
            ),
            const SizedBox(height: 24),

            // ── Hero text ────────────────────────────────────────────────
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: 'A '),
                  TextSpan(
                    text: 'Smarter',
                    style: TextStyle(color: Color(0xFF309CA3)),
                  ),
                  TextSpan(text: ' Way to Manage\nPatients'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quote icon + description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/icons/inverted-commas-icon.png', width: 24, height: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),

            // ── Semi-circle with form ────────────────────────────────────
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Semi-circle
                    Container(
                      width: semiCircleWidth > 720 ? 720 : semiCircleWidth,
                      height: semiCircleHeight,
                      padding: EdgeInsets.only(
                        top: semiCircleHeight * 0.18,
                        left: semiCircleWidth * 0.15,
                        right: semiCircleWidth * 0.15,
                        bottom: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF309CA3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(500),
                          topRight: Radius.circular(500),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock icon
                          Image.asset(
                            'assets/icons/lock-icon.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(height: 16),

                          // Title
                          const Text(
                            'Forgot Password',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Enter your email address and we'll send a password reset link.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 24),

                          // Email field
                          Container(
                            height: 38,
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: Colors.black38),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: 'Email Address',
                                      hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Send Reset Link button
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Container(
                              height: 42,
                              constraints: const BoxConstraints(maxWidth: 320),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A5C5F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

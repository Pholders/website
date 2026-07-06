import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import '../../core/routing/app_routes.dart';
import '../constants/landing_keys.dart';
import '../theme/app_theme.dart';

/// The public-facing top navigation bar used on all unauthenticated screens:
/// Landing, Login, Register, Verify Account, Forgot Password.
///
/// Single source of truth — no auth page defines its own navbar.
///
/// [actionLabel]  — text on the right-hand button ('Login' or 'Signup').
/// [actionRoute]  — GoRouter route the button navigates to.
/// [onNavLinkTap] — optional scroll callback. Pass from [LandingPage] only.
///                  On other pages leave null — tapping navigates to /get-started.
class PublicNavbar extends StatelessWidget {
  final String actionLabel;
  final String actionRoute;

  /// Scroll callback provided by [LandingPage].
  /// Receives the [GlobalKey] of the section to scroll to.
  final void Function(GlobalKey key)? onNavLinkTap;

  const PublicNavbar({
    super.key,
    required this.actionLabel,
    required this.actionRoute,
    this.onNavLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppTheme.tabletBreakpoint;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF6DD0D8).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // ── Nav links + icon (desktop only) ─────────────────────────────────
          if (isDesktop)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavLinkButton(
                    label: 'Features',
                    onTap: () => _handleTap(context, LandingKeys.features),
                  ),
                  _NavLinkButton(
                    label: 'About',
                    onTap: () => _handleTap(context, LandingKeys.about),
                  ),
                  _NavLinkButton(
                    label: 'Services',
                    onTap: () => _handleTap(context, LandingKeys.services),
                  ),
                  // PHolders icon between Services and How It Works
                  Image.asset(
                    'assets/PHolders-icon.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  _NavLinkButton(
                    label: 'How It Works',
                    onTap: () => _handleTap(context, LandingKeys.howItWorks),
                  ),
                  _NavLinkButton(
                    label: 'Support',
                    onTap: () => _handleTap(context, LandingKeys.support),
                  ),
                ],
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 16),

          // ── Action button (Login / Signup) ───────────────────────────────────
          GestureDetector(
            onTap: () => context.go(actionRoute),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF6DD0D8),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, GlobalKey key) {
    if (onNavLinkTap != null) {
      // On landing page — navigate to the corresponding page
      if (key == LandingKeys.features) {
        context.go(AppRoutes.features);
      } else if (key == LandingKeys.about) {
        context.go(AppRoutes.about);
      } else if (key == LandingKeys.services) {
        context.go(AppRoutes.services);
      } else if (key == LandingKeys.howItWorks) {
        context.go(AppRoutes.howItWorks);
      } else if (key == LandingKeys.support) {
        context.go(AppRoutes.support);
      }
    } else {
      // On another page — navigate to the corresponding page
      if (key == LandingKeys.features) {
        context.go(AppRoutes.features);
      } else if (key == LandingKeys.about) {
        context.go(AppRoutes.about);
      } else if (key == LandingKeys.services) {
        context.go(AppRoutes.services);
      } else if (key == LandingKeys.howItWorks) {
        context.go(AppRoutes.howItWorks);
      } else if (key == LandingKeys.support) {
        context.go(AppRoutes.support);
      } else {
        context.go(AppRoutes.landing);
      }
    }
  }
}

/// A tappable nav link with hover underline effect.
class _NavLinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLinkButton({required this.label, required this.onTap});

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _hovered ? const Color(0xFF309CA3) : Colors.black87,
            decoration:
                _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF309CA3),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

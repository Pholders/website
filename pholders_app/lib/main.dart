import 'package:flutter/material.dart';
import 'features/doctor/billing/presentation/billing_page.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const PholdersApp());

// ─── Router ───────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/billing',
  routes: [
    GoRoute(
      path: '/billing',
      builder: (context, state) => const BillingPage(),
    ),
  ],
);

class PholdersApp extends StatelessWidget {
  const PholdersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PHolders',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.activeTeal),
        useMaterial3: true,
      ),
    );
  }
}

// ─── Global colour tokens ─────────────────────────────────────────────────────
class AppColors {
  AppColors._();
  static const Color brandTeal     = Color(0xFF6DD0D8);
  static const Color activeTeal    = Color(0xFF309CA3);
  static const Color background    = Color(0xFFF0FAFA);
  static const Color surface       = Colors.white;
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color divider       = Color(0xFFE5E7EB);
  static const Color rowDivider    = Color(0xFFF3F4F6);
  static const Color navBg         = Color(0xFFD9D9D9);
  static const Color profileBg     = Color(0xFFD9F5F5);
}
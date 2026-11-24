import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/public_navbar.dart';
import '../data/doctor_auth_repository.dart';

/// Forgot password, in two steps: the doctor's email, then the 6-digit code
/// that was emailed with a new password.
///
/// "Send Reset Link" used to navigate back to login without calling anything,
/// and the backend's reset only looked in the patients table. Doctors now
/// have their own pair of endpoints; pharmacies have none yet, so the page
/// says so rather than pretending to send them a code.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.repository});

  /// Injected by tests; the app uses the registered one.
  final DoctorAuthRepository? repository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final DoctorAuthRepository _repo =
      widget.repository ?? sl<DoctorAuthRepository>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  /// False while asking for the email, true once a code has been sent.
  bool _codeSent = false;
  bool _busy = false;

  /// A problem with what was typed, shown under the fields.
  String? _problem;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  Future<void> _sendCode() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email)) {
      setState(() => _problem = 'Enter the email address you sign in with.');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      // The server's answer is deliberately the same for every email, so the
      // next step says "if" rather than claiming a code was sent. It is shown
      // in the form, not as a toast, which would sit over the Reset button.
      await _repo.requestPasswordReset(email: _email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, e, title: 'Code not sent');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    String? problem;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      problem = 'Enter the 6-digit code from the email.';
    } else if (password.isEmpty) {
      problem = 'Choose a new password.';
    } else if (password != _confirmController.text) {
      problem = 'The two passwords do not match.';
    }
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await _repo.resetPassword(
        email: _email,
        code: code,
        newPassword: password,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      AppFeedback.success(
          context, 'Your password has been reset. Sign in with your new password.');
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, e, title: 'Password not reset');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useDifferentEmail() => setState(() {
        _codeSent = false;
        _problem = null;
        _codeController.clear();
        _passwordController.clear();
        _confirmController.clear();
      });

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
                  Image.asset('assets/inverted-commas-icon.png',
                      width: 24, height: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),

            // ── Semi-circle with form ────────────────────────────────────
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: semiCircleWidth > 720 ? 720 : semiCircleWidth,
                  height: semiCircleHeight,
                  padding: EdgeInsets.only(
                    top: semiCircleHeight * (_codeSent ? 0.12 : 0.18),
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
                  // The second step has more fields than a short window can
                  // fit under the curve, so the form scrolls rather than
                  // overflowing.
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _codeSent ? _codeStep() : _emailStep(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _emailStep() => [
        Image.asset('assets/lock-icon.png', width: 60, height: 60),
        const SizedBox(height: 16),
        const _Title('Forgot Password'),
        const SizedBox(height: 8),
        const _Hint(
          "Enter your email address and we'll send you a 6-digit code to "
          'reset your password.',
        ),
        const SizedBox(height: 24),
        _Field(
          key: const ValueKey('reset-email'),
          controller: _emailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _sendCode(),
        ),
        ..._problemLine(),
        const SizedBox(height: 24),
        _Button(label: 'Send Reset Code', busy: _busy, onTap: _sendCode),
        const SizedBox(height: 14),
        const _Hint(
          'Password reset is for doctor accounts. Pharmacy accounts: please '
          'contact Pholders support.',
        ),
      ];

  List<Widget> _codeStep() => [
        const _Title('Reset Password'),
        const SizedBox(height: 8),
        _Hint('If $_email has a doctor account, we have emailed it a 6-digit '
            'code. Enter it below and choose a new password. The code expires '
            'in 15 minutes; check your spam folder if it has not arrived.'),
        const SizedBox(height: 16),
        _Field(
          key: const ValueKey('reset-code'),
          controller: _codeController,
          hint: '6-digit code',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 10),
        _Field(
          key: const ValueKey('reset-password'),
          controller: _passwordController,
          hint: 'New password',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 10),
        _Field(
          key: const ValueKey('reset-confirm'),
          controller: _confirmController,
          hint: 'Confirm new password',
          icon: Icons.lock_outline,
          obscure: true,
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 6),
        const _Hint(
          'At least 8 characters, with an uppercase and a lowercase letter, '
          'a number and a symbol (!@#\$%^&*).',
        ),
        ..._problemLine(),
        const SizedBox(height: 18),
        _Button(label: 'Reset Password', busy: _busy, onTap: _resetPassword),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: const Text('Send a new code',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            TextButton(
              onPressed: _busy ? null : _useDifferentEmail,
              child: const Text('Use a different email',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ];

  List<Widget> _problemLine() => [
        if (_problem != null) ...[
          const SizedBox(height: 8),
          Text(
            _problem!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A1010),
                fontWeight: FontWeight.w600),
          ),
        ],
      ];
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
}

/// A white rounded input matching the original email field.
class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.maxLength,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              maxLength: maxLength,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          height: 42,
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C5F),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

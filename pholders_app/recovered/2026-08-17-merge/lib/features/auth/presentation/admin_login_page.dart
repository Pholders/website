import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_actions.dart';
import '../../../store/app_state.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/models/admin_login_session.dart';
import 'widgets/auth_widgets.dart';

/// Admin sign-in, step one of two.
///
/// Deliberately plain and unlinked: no public navbar, no signup link, no
/// role toggle. Nothing in the app navigates here — the route is given to
/// admins out of band, so the panel is not advertised on /login.
///
/// Submitting does not sign anyone in. `/users/admin/login` only checks the
/// password and emails a 6-digit code; the session is issued on the next page.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    // Recorded before the request so the OTP page knows which address the code
    // went to. The password is never carried across.
    AdminLoginSession().email = email;

    StoreProvider.of<AppState>(context).dispatch(
      AdminLoginRequestAction(
        email: email,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      distinct: true,
      onDidChange: (prevState, state) {
        // A code was emailed. There is still no token, so this is a plain
        // navigation, not an authenticated redirect.
        final sent = state.authState.successMessage;
        if (sent != null && prevState?.authState.successMessage != sent) {
          context.go(AppRoutes.adminVerify);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF309CA3).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF309CA3),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Admin sign-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your credentials. We will email you a 6-digit '
                        'code to finish signing in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (state.authState.errorMessage != null) ...[
                        AdminNotice(
                          message: state.authState.errorMessage!,
                          isError: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AuthTextField(
                        controller: _emailController,
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.black45,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      AuthSubmitButton(
                        label: 'Continue',
                        isLoading: state.authState.isLoading,
                        onPressed: () => _submit(context),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Admin accounts are created by the PHolders team. '
                        'There is no self-registration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Inline success / error banner shared by both admin auth pages, so a failure
/// reads the same whichever step it happened on.
class AdminNotice extends StatelessWidget {
  const AdminNotice({super.key, required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.error : const Color(0xFF309CA3);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }
}

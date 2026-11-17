import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import 'auth_widgets.dart';

/// The sign-in form, drawn for the teal circle. One form serves doctors and
/// pharmacies: the middleware finds which kind of account the email belongs to.
///
/// Matches Figma frame "Doctor login". [LandingPage] shows it in place of the
/// doctors when the route is /login. Dispatches [LoginRequestAction] to the
/// Redux store on submit.
class LoginPanel extends StatefulWidget {
  const LoginPanel({super.key, required this.fieldWidth, this.storage});

  /// Where "Remember me" keeps the email. Defaults to the app's own.
  final TokenStorage? storage;

  /// Width of the fields column; the rule above "Sign up" is always full width.
  final double fieldWidth;

  @override
  State<LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<LoginPanel> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  TokenStorage? get _storage =>
      widget.storage ??
      (sl.isRegistered<TokenStorage>() ? sl<TokenStorage>() : null);

  @override
  void initState() {
    super.initState();
    _restoreEmail();
  }

  /// Fills in the email from last time, if "Remember me" was ticked when it
  /// last signed in. The password is never kept by the app.
  Future<void> _restoreEmail() async {
    final email = await _storage?.readRememberedEmail();
    if (!mounted || email == null || email.isEmpty) return;
    // Someone who started typing before storage answered keeps what they typed.
    if (_emailController.text.isNotEmpty) return;
    setState(() {
      _emailController.text = email;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // The middleware keeps the email once it has signed in, or forgets it
    // when the box is unticked. The password is only ever offered to the
    // browser's own password manager, and only when the box is ticked.
    TextInput.finishAutofillContext(shouldSave: _rememberMe);

    // The router's auth guard navigates to the right dashboard once the store
    // reports an authenticated session, so there is no context.go() here.
    // No role is given: the middleware tries the doctor login, then pharmacy.
    StoreProvider.of<AppState>(context).dispatch(
      LoginRequestAction(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LoginForm(
      formKey: _formKey,
      fieldWidth: widget.fieldWidth,
      emailController: _emailController,
      passwordController: _passwordController,
      rememberMe: _rememberMe,
      obscurePassword: _obscurePassword,
      onRememberMeChanged: (v) => setState(() => _rememberMe = v ?? false),
      onTogglePassword: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmit: () => _submit(context),
      onForgotPassword: () => context.go(AppRoutes.forgotPassword),
      onSignUp: () => context.go(AppRoutes.register),
    );
  }
}

// ─── Login form ───────────────────────────────────────────────────────────────

/// The sign-in form as drawn on the teal circle: pill mascot, welcome, fields,
/// and the sign-up prompt below a rule that spans the full width available.
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.fieldWidth,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignUp,
  });
  final GlobalKey<FormState> formKey;

  /// Width of the fields column; the rule above "Sign up" is always full width.
  final double fieldWidth;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  /// Dark teal for secondary text on the teal circle.
  static const Color _mutedOnTeal = Color(0xFF1E6B70);

  /// Link blue from the design.
  static const Color _linkBlue = Color(0xFF0057FF);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _LoginViewModel>(
      converter: (store) => _LoginViewModel(
        isLoading: store.state.authState.isLoading,
        errorMessage: store.state.authState.errorMessage,
      ),
      builder: (context, vm) {
        // Grouping the fields lets the browser's password manager see them
        // as one login, to save and fill in together.
        return AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/pill-icon.png',
                  height: 104,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to access your patients, appointments, and prescriptions securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _mutedOnTeal,
                    letterSpacing: 0.3,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner
                      if (vm.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      AuthTextField(
                        controller: emailController,
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
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
                        controller: passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: Colors.black54,
                          ),
                          onPressed: onTogglePassword,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // The words toggle the box too: a 14px box alone
                            // is a hard target to hit.
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onRememberMeChanged(!rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: Checkbox(
                                        value: rememberMe,
                                        onChanged: onRememberMeChanged,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        side: const BorderSide(
                                            color: Colors.white),
                                        fillColor: const WidgetStatePropertyAll(
                                            Colors.white),
                                        checkColor: AppTheme.landingTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: onForgotPassword,
                                child: const Text(
                                  'Forgot password',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _linkBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Center(
                        child: _LetsStartButton(
                          isLoading: vm.isLoading,
                          onPressed: onSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Full-width rule, as drawn across the circle in the design.
                Container(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 30),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onSignUp,
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _linkBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoginViewModel {
  const _LoginViewModel({
    required this.isLoading,
    this.errorMessage,
  });
  final bool isLoading;
  final String? errorMessage;
}

// ─── "Let's start" button ─────────────────────────────────────────────────────

/// Raised teal pill that submits the form. While signing in it ignores
/// further clicks; the splash screen is the loader, so it shows no spinner.
class _LetsStartButton extends StatelessWidget {
  const _LetsStartButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF45AFB4),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "Let's start",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

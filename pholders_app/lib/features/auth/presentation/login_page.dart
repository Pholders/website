import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_state.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/auth_widgets.dart';

/// Doctor / Pharmacy login page.
///
/// Matches Figma frame "Doctor login".
/// Uses the shared [PublicNavbar] — no local navbar code here.
/// Dispatches [LoginRequestAction] to the Redux store on submit.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String _role = AppConstants.roleDoctor;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // The router's auth guard navigates to the right dashboard once the store
    // reports an authenticated session, so there is no context.go() here.
    StoreProvider.of<AppState>(context).dispatch(
      LoginRequestAction(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < AppTheme.mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Teal ellipse background
          Positioned(
            left: size.width * 0.18,
            top: size.height * 0.32,
            child: Container(
              width: size.width * 0.64,
              height: size.height * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6DD0D8).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Shared public navbar — Signup button on the right
          const Positioned(
            top: 36,
            left: 77,
            right: 77,
            child: PublicNavbar(
              actionLabel: 'Signup',
              actionRoute: AppRoutes.register,
            ),
          ),

          // Main content
          isMobile
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context, size),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Size size) {
    return Row(
      children: [
        // Left: illustration
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 80, top: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'A '),
                      TextSpan(
                        text: 'Smarter',
                        style: TextStyle(color: Color(0xFF309CA3)),
                      ),
                      TextSpan(text: '\nWay to\nManage Patients'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 420,
                  child: Text(
                    'Access patient records, create secure digital prescriptions, and monitor health updates all in one platform.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black45,
                      letterSpacing: 0.5,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DD0D8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.medication_outlined,
                      size: 40,
                      color: Color(0xFF309CA3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: login form
        Expanded(
          flex: 6,
          child: Center(
            child: _LoginForm(
              formKey: _formKey,
              role: _role,
              onRoleChanged: (r) => setState(() => _role = r),
              emailController: _emailController,
              passwordController: _passwordController,
              rememberMe: _rememberMe,
              obscurePassword: _obscurePassword,
              onRememberMeChanged: (v) =>
                  setState(() => _rememberMe = v ?? false),
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: () => _submit(context),
              onForgotPassword: () => context.go(AppRoutes.forgotPassword),
              onSignUp: () => context.go(AppRoutes.register),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: _LoginForm(
          formKey: _formKey,
          role: _role,
          onRoleChanged: (r) => setState(() => _role = r),
          emailController: _emailController,
          passwordController: _passwordController,
          rememberMe: _rememberMe,
          obscurePassword: _obscurePassword,
          onRememberMeChanged: (v) =>
              setState(() => _rememberMe = v ?? false),
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onSubmit: () => _submit(context),
          onForgotPassword: () => context.go(AppRoutes.forgotPassword),
          onSignUp: () => context.go(AppRoutes.register),
        ),
      ),
    );
  }
}

// ─── Login form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {

  const _LoginForm({
    required this.formKey,
    required this.role,
    required this.onRoleChanged,
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
  final String role;
  final ValueChanged<String> onRoleChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _LoginViewModel>(
      converter: (store) => _LoginViewModel(
        isLoading: store.state.authState.isLoading,
        errorMessage: store.state.authState.errorMessage,
      ),
      builder: (context, vm) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to access your patients, appointments, and prescriptions securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Error banner
                if (vm.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
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
                  const SizedBox(height: 16),
                ],

                // Doctors and pharmacies authenticate against different
                // endpoints, so the account type has to be chosen up front.
                _RoleSelector(selected: role, onChanged: onRoleChanged),
                const SizedBox(height: 20),

                AuthTextField(
                  controller: emailController,
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
                  controller: passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.black45,
                    ),
                    onPressed: onTogglePassword,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: onRememberMeChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onForgotPassword,
                      child: const Text(
                        'Forgot password',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF003BFC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                AuthSubmitButton(
                  label: "Let's start",
                  isLoading: vm.isLoading,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: onSignUp,
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0x99003BFC),
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

// ─── Account type selector ────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          _RoleTab(
            label: 'Doctor',
            icon: Icons.medical_services_outlined,
            isSelected: selected == AppConstants.roleDoctor,
            onTap: () => onChanged(AppConstants.roleDoctor),
          ),
          _RoleTab(
            label: 'Pharmacy',
            icon: Icons.local_pharmacy_outlined,
            isSelected: selected == AppConstants.rolePharmacy,
            onTap: () => onChanged(AppConstants.rolePharmacy),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primary : Colors.black45,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primary : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

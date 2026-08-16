import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../store/app_state.dart';
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
  /// Vertical space the floating navbar occupies (top offset 36 + 64 tall),
  /// plus breathing room. Content must start below this or it overlaps.
  static const double _navbarReserve = 124;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  /// Doctors and pharmacies sign in through separate endpoints and the API
  /// returns no role field, so the user has to tell us which they are.
  String _selectedRole = AppConstants.roleDoctor;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    StoreProvider.of<AppState>(context).dispatch(
      LoginRequestAction(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      ),
    );
  }

  void _handleAuthResult(BuildContext context, AppState state) {
    if (!state.authState.isAuthenticated) {
      return;
    }

    final role = state.authState.role;
    if (role == 'doctor') {
      context.go(AppRoutes.doctorDashboard);
    } else if (role == 'pharmacy') {
      context.go(AppRoutes.pharmacyDashboard);
    } else {
      context.go(AppRoutes.doctorDashboard);
    }
  }

  void _showDevRolePicker(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF309CA3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.developer_mode,
                  color: Color(0xFF309CA3),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dev Mode — Choose Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Backend is under construction.\nPick a role to test the screens.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _DevRoleButton(
                      icon: Icons.medical_services_outlined,
                      label: 'Doctor',
                      color: const Color(0xFF309CA3),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _loginAs(context, 'doctor');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DevRoleButton(
                      icon: Icons.local_pharmacy_outlined,
                      label: 'Pharmacy',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _loginAs(context, 'pharmacy');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loginAs(BuildContext context, String role) {
    // Dispatch a fake successful login so the Redux store is in the right state.
    StoreProvider.of<AppState>(context).dispatch(
      LoginSuccessAction(
        token: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        userName: _emailController.text.trim().split('@').first,
      ),
    );

    // Navigate to the appropriate dashboard.
    if (role == 'doctor') {
      context.go(AppRoutes.doctorDashboard);
    } else {
      context.go(AppRoutes.pharmacyDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < AppTheme.mobileBreakpoint;

    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      distinct: true,
      onDidChange: (prevState, state) {
        if (prevState?.authState.isAuthenticated ==
            state.authState.isAuthenticated) {
          return;
        }
        if (state.authState.isAuthenticated) {
          _handleAuthResult(context, state);
        }
      },
      builder: (context, state) {
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
              Positioned(
                top: 36,
                left: 77,
                right: 77,
                child: PublicNavbar(
                  actionLabel: 'Signup',
                  actionRoute: AppRoutes.register,
                ),
              ),

              // Main content
              Positioned.fill(
                child: isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context, size),
              ),
            ],
          ),
        );
      },
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

        // Right: login form.
        //
        // Reserves the navbar strip (top: 36 + 64 tall) so the heading cannot
        // ride up under it, and scrolls once the form outgrows what is left.
        Expanded(
          flex: 6,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.only(top: _navbarReserve, bottom: 32),
                  child: Center(
                    child: _LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      rememberMe: _rememberMe,
                      obscurePassword: _obscurePassword,
                      selectedRole: _selectedRole,
                      onRoleChanged: (role) =>
                          setState(() => _selectedRole = role),
                      onRememberMeChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: () => _submit(context),
                      onForgotPassword: () =>
                          context.go(AppRoutes.forgotPassword),
                      onSignUp: () => context.go(AppRoutes.register),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: _navbarReserve,
          bottom: 40,
        ),
        child: _LoginForm(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          rememberMe: _rememberMe,
          obscurePassword: _obscurePassword,
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
          onRememberMeChanged: (v) => setState(() => _rememberMe = v ?? false),
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

// ─── Role toggle ──────────────────────────────────────────────────────────────

/// Doctor / Pharmacy switch shown above the credentials.
///
/// The two roles authenticate through different endpoints, so this choice
/// decides which one the login request goes to.
class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.selectedRole, required this.onChanged});

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF6DD0D8).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleToggleOption(
              label: 'Doctor',
              icon: Icons.medical_services_outlined,
              selected: selectedRole == AppConstants.roleDoctor,
              onTap: () => onChanged(AppConstants.roleDoctor),
            ),
          ),
          Expanded(
            child: _RoleToggleOption(
              label: 'Pharmacy',
              icon: Icons.local_pharmacy_outlined,
              selected: selectedRole == AppConstants.rolePharmacy,
              onTap: () => onChanged(AppConstants.rolePharmacy),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleToggleOption extends StatelessWidget {
  const _RoleToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Sign in as $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                color: selected ? const Color(0xFF309CA3) : Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? const Color(0xFF309CA3) : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _LoginViewModel>(
      converter: (store) => _LoginViewModel(
        isLoading: store.state.authState.isLoading,
        errorMessage: store.state.authState.errorMessage,
        successMessage: store.state.authState.successMessage,
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
                if (vm.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF309CA3).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: const Color(0xFF309CA3).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      vm.successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF309CA3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _RoleToggle(
                  selectedRole: selectedRole,
                  onChanged: onRoleChanged,
                ),
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
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const _LoginViewModel({
    required this.isLoading,
    this.errorMessage,
    this.successMessage,
  });
}

// ─── Dev role picker button ───────────────────────────────────────────────────

class _DevRoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DevRoleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

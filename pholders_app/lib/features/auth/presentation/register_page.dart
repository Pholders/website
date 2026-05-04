import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/auth_widgets.dart';
/// Role selection + personal info step 1 of registration.
///
/// Matches Figma frames "Doctor Create account 1" and "Pharmacy Create account 1".
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'doctor'; // 'doctor' | 'pharmacy'
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < AppTheme.mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ellipse
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

          // Shared public navbar — Login button on the right
          Positioned(
            top: 36,
            left: 77,
            right: 77,
            child: PublicNavbar(
              actionLabel: 'Login',
              actionRoute: AppRoutes.login,
            ),
          ),

          // Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: 120,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join the platform to manage patients, prescriptions, and consultations securely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role selector
                      _RoleSelector(
                        selectedRole: _selectedRole,
                        onChanged: (role) =>
                            setState(() => _selectedRole = role),
                      ),
                      const SizedBox(height: 24),

                      // Personal info
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _firstNameController,
                              hint: 'First Name',
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              controller: _lastNameController,
                              hint: 'Last Name',
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _phoneController,
                              hint: _selectedRole == 'pharmacy'
                                  ? 'Pharmacy Number'
                                  : 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              controller: _emailController,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Security info
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Security Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
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
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 8) return 'Min 8 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Next button
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 120,
                          child: AuthSubmitButton(
                            label: 'Next',
                            isLoading: false,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.go(AppRoutes.verifyAccount);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Role selector ------------------------------------------------------------

class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleOption(
          label: 'Doctor',
          value: 'doctor',
          selected: selectedRole == 'doctor',
          onTap: () => onChanged('doctor'),
        ),
        const SizedBox(width: 16),
        _RoleOption(
          label: 'Pharmacy',
          value: 'pharmacy',
          selected: selectedRole == 'pharmacy',
          onTap: () => onChanged('pharmacy'),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF309CA3).withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF309CA3) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF309CA3)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF309CA3),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? const Color(0xFF309CA3)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';
import '../data/models/signup_session.dart';

/// Role selection + personal info step 1 of registration.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'doctor';
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

  /// Returns the first problem with the form, or null when it is valid.
  ///
  /// The password rules mirror the API's validator so the user is told at this
  /// step rather than by a rejected signup two screens later.
  String? _validate() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      return 'Please fill in all fields.';
    }

    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    // The API stores the phone number in a VARCHAR(20) column.
    if (_phoneController.text.trim().length > 20) {
      return 'Phone number must be 20 characters or fewer.';
    }

    final password = _passwordController.text;
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain a lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain a number.';
    }
    if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(password)) {
      return 'Password must contain a special character.';
    }
    if (password != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }

    return null;
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
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 60, right: 60),
                  child: PublicNavbar(
                    actionLabel: 'Login',
                    actionRoute: AppRoutes.login,
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/inverted-commas-icon.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: semiCircleWidth > 720 ? 720 : semiCircleWidth,
                          height: semiCircleHeight,
                          padding: EdgeInsets.only(
                            top: semiCircleHeight * 0.16,
                            left: semiCircleWidth * 0.12,
                            right: semiCircleWidth * 0.12,
                            bottom: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF309CA3),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(500),
                              topRight: Radius.circular(500),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Join the platform to manage patients, prescriptions, and consultations securely.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RoleSelector(
                                  selectedRole: _selectedRole,
                                  onChanged: (role) =>
                                      setState(() => _selectedRole = role),
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Field(
                                        controller: _firstNameController,
                                        hint: 'First Name',
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Field(
                                        controller: _lastNameController,
                                        hint: 'Last Name',
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Field(
                                        controller: _phoneController,
                                        hint: _selectedRole == 'pharmacy'
                                            ? 'Pharmacy Number'
                                            : 'Phone Number',
                                        icon: Icons.phone_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Field(
                                        controller: _emailController,
                                        hint: 'Email address',
                                        icon: Icons.email_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Security Information',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Field(
                                        controller: _passwordController,
                                        hint: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 14,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Field(
                                        controller: _confirmPasswordController,
                                        hint: 'Confirm password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscureConfirm,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm,
                                          ),
                                          child: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 14,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // The panel can be shorter than the form on
                                // compact browser windows. A fixed gap keeps
                                // the content scrollable in that case.
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF6DD0D8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      final error = _validate();
                                      if (error != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                        return;
                                      }

                                      final session = SignupSession();
                                      session.firstName =
                                          _firstNameController.text.trim();
                                      session.lastName =
                                          _lastNameController.text.trim();
                                      session.email =
                                          _emailController.text.trim();
                                      session.phone =
                                          _phoneController.text.trim();
                                      session.password =
                                          _passwordController.text;
                                      session.role = _selectedRole;

                                      context.go(
                                        _selectedRole == 'pharmacy'
                                            ? AppRoutes.pharmacyRegisterStep2
                                            : AppRoutes.registerStep2,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A5C5F),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Next',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          child: Image.asset(
                            'assets/pill-icon.png',
                            width: 75,
                            height: 75,
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

class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleOption(
            label: 'Doctor',
            selected: selectedRole == 'doctor',
            onTap: () => onChanged('doctor'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleOption(
            label: 'Pharmacy',
            selected: selectedRole == 'pharmacy',
            onTap: () => onChanged('pharmacy'),
          ),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.black : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.black : Colors.white70,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.black87 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black38),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../data/models/doctor_registration_draft.dart';

/// Step 1 of registration, drawn for the teal circle — Figma "Doctor Create
/// account 1". [LandingPage] shows it in place of the doctors on /register.
///
/// Collects the personal and security details, then hands them to step 2
/// (/register/step-2) as a [DoctorRegistrationDraft]; step 2 submits both
/// halves in one signup call.
class SignupPanel extends StatefulWidget {
  const SignupPanel({super.key, this.compact = false});

  /// Phones: the two columns share the width instead of the design's fixed
  /// 193px columns with a wide gap.
  final bool compact;

  @override
  State<SignupPanel> createState() => _SignupPanelState();
}

class _SignupPanelState extends State<SignupPanel> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = AppConstants.roleDoctor;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Clear any result left over from a previous registration attempt, so the
    // next page does not immediately act on a stale success.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context).dispatch(const ResetSignupAction());
      }
    });
  }

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

  /// Validates step 1 and carries the details through to step 2.
  void _next() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? problem;
    if (firstName.isEmpty || lastName.isEmpty) {
      problem = 'Please enter your first and last name.';
    } else if (!email.contains('@') || !email.contains('.')) {
      problem = 'Please enter a valid email address.';
    } else if (phone.isEmpty) {
      problem = 'Please enter your phone number.';
    } else if (password.isEmpty) {
      problem = 'Please choose a password.';
    } else if (password != confirm) {
      problem = 'The two passwords do not match.';
    } else if (_role != AppConstants.roleDoctor) {
      // Only the doctor signup endpoint is wired up so far.
      problem =
          'Pharmacy registration is not connected yet — please choose Doctor.';
    }

    setState(() => _error = problem);
    if (problem != null) return;

    context.go(
      AppRoutes.registerStep2,
      extra: DoctorRegistrationDraft(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPharmacy = _role == AppConstants.rolePharmacy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/pill-icon.png', height: 104, fit: BoxFit.contain),
        const SizedBox(height: 6),
        const Text(
          'Create Account',
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
          'Join the platform to manage patients, prescriptions, and consultations securely.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: _mutedOnTeal,
            letterSpacing: 0.3,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        _pair(
          _RoleOption(
            label: 'Doctor',
            selected: !isPharmacy,
            onTap: () => setState(() => _role = AppConstants.roleDoctor),
          ),
          _RoleOption(
            label: 'Pharmacy',
            selected: isPharmacy,
            onTap: () => setState(() => _role = AppConstants.rolePharmacy),
          ),
        ),
        const SizedBox(height: 20),

        _section('Personal Information'),
        _pair(
          _SignupField(
            controller: _firstNameController,
            hint: 'First Name',
            icon: Icons.person_outline,
          ),
          _SignupField(
            controller: _lastNameController,
            hint: 'Last Name',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 11),
        _pair(
          _SignupField(
            controller: _phoneController,
            hint: isPharmacy ? 'Pharmacy Number' : 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _SignupField(
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 22),

        _section('Security Information'),
        _pair(
          _SignupField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          _SignupField(
            controller: _confirmPasswordController,
            hint: 'Confirm password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmitted: (_) => _next(),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: _rowWidth,
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A1010),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),

        // Step dots, with Next at the right-hand edge of the form.
        SizedBox(
          width: _rowWidth,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(top: 0, child: _StepDots(current: 0)),
              Positioned(
                right: 0,
                bottom: 0,
                child: _NextButton(onPressed: _next),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  static const double _columnWidth = 193;
  static const double _designGap = 73;

  /// Dark teal for secondary text on the teal circle.
  static const Color _mutedOnTeal = Color(0xFF1E6B70);

  double? get _rowWidth =>
      widget.compact ? null : _columnWidth * 2 + _designGap;

  /// Two controls side by side, as the design's two columns.
  Widget _pair(Widget left, Widget right) {
    if (widget.compact) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      );
    }
    return SizedBox(
      width: _rowWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: _columnWidth, child: left),
          SizedBox(width: _columnWidth, child: right),
        ],
      ),
    );
  }

  /// "Personal Information" style heading over the left column.
  Widget _section(String title) {
    return SizedBox(
      width: _rowWidth,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    );
  }
}

// ─── Doctor / Pharmacy option ─────────────────────────────────────────────────

/// A translucent pill with a radio dot: black when chosen, white when not.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: selected ? 0.28 : 0.16),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.7 : 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.black : Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
                // Balances the dot so the label sits in the middle.
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

/// White rounded field with a leading icon and, for passwords, an eye toggle.
class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;

  /// Shows the eye toggle when set.
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onToggleObscure != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step dots ────────────────────────────────────────────────────────────────

/// Which of the two registration steps this is: filled for the current one.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Container(
            width: 21,
            height: 16,
            decoration: BoxDecoration(
              color: i == current ? const Color(0xFF6DD0D8) : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6DD0D8)),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Next ─────────────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF45AFB4),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              SizedBox(width: 6),
              Icon(Icons.east, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

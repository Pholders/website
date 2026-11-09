import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../data/models/doctor_registration_draft.dart';
import 'pharmacy_details_form.dart';
import 'practice_details_form.dart';
import 'signup_kit.dart';
import 'verify_code_form.dart';

/// Step 1 of registration, on a white card in the teal circle.
/// [LandingPage] shows it in place of the doctors on /register.
///
/// Collects the personal and security details, then shows step 2 in its
/// place with them as a [DoctorRegistrationDraft]: the practice for a doctor
/// ([PracticeDetailsForm]), the pharmacy for a pharmacy
/// ([PharmacyDetailsForm]). Step 2 submits both halves in one signup call.
/// Back from step 2 returns here with everything still filled in.
///
/// Once the account is created, step 3 ([VerifyCodeForm]) takes step 2's
/// place: the emailed code that activates it. There is no going back from
/// there, since the account exists.
class SignupPanel extends StatefulWidget {
  const SignupPanel({super.key, this.compact = false});

  /// Phones: one column, the card the width of the screen.
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Step 1's details once they pass: step 2 shows while set.
  DoctorRegistrationDraft? _draft;

  /// The account was created: step 3, the emailed code, shows.
  bool _registered = false;

  /// Signing up a pharmacy rather than a doctor.
  bool _pharmacy = false;

  /// Set once Continue has been pressed: from then on each field says what
  /// is wrong with it as it is corrected.
  bool _tried = false;

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
    for (final c in [_passwordController, _confirmPasswordController]) {
      c.addListener(() => setState(() {}));
    }
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

  // ── Checks ────────────────────────────────────────────────────────────────

  String? get _firstNameProblem =>
      _firstNameController.text.trim().isEmpty ? 'Enter your first name' : null;
  String? get _lastNameProblem =>
      _lastNameController.text.trim().isEmpty ? 'Enter your last name' : null;
  String? get _phoneProblem =>
      _phoneController.text.trim().isEmpty ? 'Enter your phone number' : null;
  String? get _emailProblem {
    final e = _emailController.text.trim();
    return (!e.contains('@') || !e.contains('.'))
        ? 'Enter a valid email address'
        : null;
  }

  String? get _passwordProblem =>
      _passwordController.text.isEmpty ? 'Choose a password' : null;
  String? get _confirmProblem =>
      _confirmPasswordController.text != _passwordController.text
          ? 'The passwords do not match'
          : null;

  /// Validates step 1 and moves on to step 2 with its details.
  void _next() {
    setState(() => _tried = true);
    final problems = [
      _firstNameProblem,
      _lastNameProblem,
      _phoneProblem,
      _emailProblem,
      _passwordProblem,
      _confirmProblem,
    ];
    if (problems.any((p) => p != null)) return;

    setState(() => _draft = DoctorRegistrationDraft(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    String? shown(String? problem) => _tried ? problem : null;

    Widget pair(Widget a, Widget b) => compact
        ? Column(children: [a, const SizedBox(height: 12), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          );

    final confirm = _confirmPasswordController.text;
    final matches = confirm.isNotEmpty && confirm == _passwordController.text;

    final card = SignupCard(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SignupProgress(step: 1, of: 3, label: 'Your details'),
          const SizedBox(height: 20),
          SignupHeading(
            title: 'Create your account',
            subtitle: _pharmacy
                ? 'Receive, check and dispense prescriptions securely, in '
                    'one place.'
                : 'Manage patients, prescriptions and consultations '
                    'securely, in one place.',
            compact: compact,
          ),
          const SizedBox(height: 20),
          _RoleSwitch(
            pharmacy: _pharmacy,
            onChanged: (pharmacy) => setState(() => _pharmacy = pharmacy),
          ),
          const SizedBox(height: 22),
          const SignupSectionLabel('Personal information'),
          const SizedBox(height: 10),
          pair(
            SignupField(
              controller: _firstNameController,
              label: 'First name',
              icon: Icons.person_outline_rounded,
              error: shown(_firstNameProblem),
              onChanged: _tried ? (_) => setState(() {}) : null,
              autofillHints: const [AutofillHints.givenName],
            ),
            SignupField(
              controller: _lastNameController,
              label: 'Last name',
              icon: Icons.person_outline_rounded,
              error: shown(_lastNameProblem),
              onChanged: _tried ? (_) => setState(() {}) : null,
              autofillHints: const [AutofillHints.familyName],
            ),
          ),
          const SizedBox(height: 12),
          pair(
            SignupField(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              error: shown(_phoneProblem),
              onChanged: _tried ? (_) => setState(() {}) : null,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            SignupField(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              error: shown(_emailProblem),
              onChanged: _tried ? (_) => setState(() {}) : null,
              autofillHints: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: 20),
          const SignupSectionLabel('Security'),
          const SizedBox(height: 10),
          pair(
            SignupField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              error: shown(_passwordProblem),
              autofillHints: const [AutofillHints.newPassword],
            ),
            SignupField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              error: shown(_confirmProblem),
              onSubmitted: (_) => _next(),
              trailingOk: matches,
            ),
          ),
          const SizedBox(height: 12),
          _Strength(password: _passwordController.text),
          const SizedBox(height: 24),
          SignupButton(label: 'Continue', onTap: _next),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already have an account?',
                  style: TextStyle(fontSize: 14, color: SignupColors.body)),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                style: TextButton.styleFrom(
                  foregroundColor: SignupColors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Log in',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );

    final draft = _draft;
    final step = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          // Later steps come in from the right; back, step 1 from the left.
          position: Tween(
            begin: Offset(child.key == const ValueKey(1) ? -0.08 : 0.08, 0),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: _registered
          ? KeyedSubtree(
              key: const ValueKey(3),
              child: VerifyCodeForm(compact: compact),
            )
          : draft == null
              ? KeyedSubtree(key: const ValueKey(1), child: card)
              : KeyedSubtree(
                  key: const ValueKey(2),
                  child: _pharmacy
                      ? PharmacyDetailsForm(
                          draft: draft,
                          compact: compact,
                          onBack: () => setState(() => _draft = null),
                          onRegistered: () =>
                              setState(() => _registered = true),
                        )
                      : PracticeDetailsForm(
                          draft: draft,
                          compact: compact,
                          onBack: () => setState(() => _draft = null),
                          onRegistered: () =>
                              setState(() => _registered = true),
                        ),
                ),
    );

    return AutofillGroup(
      child: compact ? step : Center(child: SizedBox(width: 600, child: step)),
    );
  }
}

// ─── Doctor / Pharmacy ────────────────────────────────────────────────────────

/// Doctor or Pharmacy on a track, the chosen one dark.
class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch({required this.pharmacy, required this.onChanged});

  final bool pharmacy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, IconData icon, bool isPharmacy) {
      final on = pharmacy == isPharmacy;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(isPharmacy),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              decoration: BoxDecoration(
                color: on ? SignupColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: SignupColors.ink.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 18, color: on ? Colors.white : SignupColors.body),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : SignupColors.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SignupColors.hairline),
      ),
      child: Row(
        children: [
          option('Doctor', Icons.medical_services_outlined, false),
          option('Pharmacy', Icons.local_pharmacy_outlined, true),
        ],
      ),
    );
  }
}

// ─── Password strength ────────────────────────────────────────────────────────

/// How strong the password is, from its length and the kinds of character
/// in it: four bars and a word. A guide only; the server sets the rules.
class _Strength extends StatelessWidget {
  const _Strength({required this.password});
  final String password;

  /// 0 for none, then 1 (weak) to 4 (strong).
  static int score(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (RegExp('[a-z]').hasMatch(p) && RegExp('[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final s = score(password);
    const words = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      Color(0xFFE6EEEF),
      SignupColors.danger,
      Color(0xFFE59A2F),
      Color(0xFF3FB3BC),
      Color(0xFF2E9D57),
    ];
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              decoration: BoxDecoration(
                color: i <= s ? colors[s] : const Color(0xFFE6EEEF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        SizedBox(
          width: 118,
          child: Text(
            s == 0 ? 'Password strength' : words[s],
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: s == 0 ? SignupColors.body : colors[s],
            ),
          ),
        ),
      ],
    );
  }
}

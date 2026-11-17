import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/constants/sa_locations.dart';
import '../../data/models/doctor_registration_draft.dart';
import 'signup_kit.dart';

/// Step 2 of signing up: professional and practice details, on the sign-up
/// card. Submits both steps in one signup call, then moves on to verifying
/// the email.
///
/// Shown by step 1 in its place ([SignupPanel]), and by the
/// /register/step-2 page.
class PracticeDetailsForm extends StatefulWidget {
  const PracticeDetailsForm({
    super.key,
    required this.draft,
    required this.onBack,
    this.onRegistered,
    this.compact = false,
  });

  /// The personal details from step 1.
  final DoctorRegistrationDraft draft;

  /// Back to step 1.
  final VoidCallback onBack;

  /// The account was created and its code emailed: on to step 3. Without
  /// it, the /verify page takes over.
  final VoidCallback? onRegistered;

  /// Phones: one column.
  final bool compact;

  @override
  State<PracticeDetailsForm> createState() => _PracticeDetailsFormState();
}

class _PracticeDetailsFormState extends State<PracticeDetailsForm> {
  final _clinicNameController = TextEditingController();
  final _hpcsaController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedCity = '';
  String _selectedProvince = '';

  /// Set once Create account has been pressed: from then on each field says
  /// what is wrong with it as it is corrected.
  bool _tried = false;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _hpcsaController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // ── Checks ────────────────────────────────────────────────────────────────

  String? get _clinicProblem => _clinicNameController.text.trim().isEmpty
      ? 'Enter your clinic or practice name'
      : null;
  String? get _hpcsaProblem =>
      _hpcsaController.text.trim().isEmpty ? 'Enter your HPCSA number' : null;
  String? get _specializationProblem =>
      _specializationController.text.trim().isEmpty
          ? 'Enter your specialization'
          : null;
  String? get _experienceProblem =>
      int.tryParse(_experienceController.text.trim()) == null
          ? 'Enter your years of experience as a number'
          : null;
  String? get _provinceProblem =>
      _selectedProvince.isEmpty ? 'Choose your province' : null;
  String? get _cityProblem => _selectedCity.isEmpty ? 'Choose your city' : null;

  /// Validates the practice details and submits the whole registration.
  void _register() {
    final draft = widget.draft;
    setState(() => _tried = true);
    final problems = [
      _clinicProblem,
      _hpcsaProblem,
      _specializationProblem,
      _experienceProblem,
      _provinceProblem,
      _cityProblem,
    ];
    if (problems.any((p) => p != null)) return;

    StoreProvider.of<AppState>(context).dispatch(
      DoctorSignupRequestAction(
        firstName: draft.firstName,
        lastName: draft.lastName,
        email: draft.email,
        phone: draft.phone,
        password: draft.password,
        hpcsaNumber: _hpcsaController.text.trim(),
        specialization: _specializationController.text.trim(),
        experience: int.parse(_experienceController.text.trim()),
        clinicName: _clinicNameController.text.trim(),
        city: _selectedCity,
        province: _selectedProvince,
        // The backend geocodes this field and only resolves place names, so
        // the chosen city doubles as the practice address.
        clinicAddress: _selectedCity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      onWillChange: (previous, next) {
        // Registered: on to the emailed code.
        if (previous?.signupEmail == null && next.signupEmail != null) {
          final onRegistered = widget.onRegistered;
          onRegistered == null
              ? context.go(AppRoutes.verifyAccount)
              : onRegistered();
        }
      },
      builder: _form,
    );
  }

  Widget _form(BuildContext context, _ViewModel vm) {
    final compact = widget.compact;
    String? shown(String? problem) => _tried ? problem : null;
    void recheck(String _) {
      if (_tried) setState(() {});
    }

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

    return SignupCard(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SignupProgress(step: 2, of: 3, label: 'Your practice'),
          const SizedBox(height: 20),
          SignupHeading(
            title: 'Tell us about your practice',
            subtitle: 'So patients and pharmacies know who they are dealing '
                'with. ${widget.draft.firstName}, one more step after this.',
            compact: compact,
          ),
          const SizedBox(height: 24),
          const SignupSectionLabel('Professional'),
          const SizedBox(height: 10),
          pair(
            SignupField(
              controller: _hpcsaController,
              label: 'HPCSA number',
              icon: Icons.badge_outlined,
              error: shown(_hpcsaProblem),
              onChanged: recheck,
            ),
            SignupField(
              controller: _experienceController,
              label: 'Years of experience',
              icon: Icons.workspace_premium_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              error: shown(_experienceProblem),
              onChanged: recheck,
            ),
          ),
          const SizedBox(height: 12),
          SignupField(
            controller: _specializationController,
            label: 'Specialization',
            icon: Icons.medical_services_outlined,
            error: shown(_specializationProblem),
            onChanged: recheck,
          ),
          const SizedBox(height: 20),
          const SignupSectionLabel('Practice'),
          const SizedBox(height: 10),
          SignupField(
            controller: _clinicNameController,
            label: 'Clinic or practice name',
            icon: Icons.local_hospital_outlined,
            error: shown(_clinicProblem),
            onChanged: recheck,
          ),
          const SizedBox(height: 12),
          pair(
            SignupDropdown(
              label: 'Province',
              icon: Icons.map_outlined,
              value: _selectedProvince,
              items: SaLocations.provinces,
              error: shown(_provinceProblem),
              onChanged: (v) => setState(() {
                _selectedProvince = v;
                // The city list depends on the province, so a city picked
                // under the previous one must not survive the change.
                _selectedCity = '';
              }),
            ),
            SignupDropdown(
              label: 'City',
              disabledLabel: 'Choose a province first',
              icon: Icons.location_city_outlined,
              value: _selectedCity,
              items: SaLocations.citiesFor(_selectedProvince),
              error: _selectedProvince.isEmpty ? null : shown(_cityProblem),
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 18),
            SignupBanner(text: vm.errorMessage!),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              SignupBackButton(onTap: widget.onBack),
              const SizedBox(width: 12),
              Expanded(
                child: SignupButton(
                  label: 'Create account',
                  icon: Icons.check_rounded,
                  busy: vm.isLoading,
                  onTap: _register,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Next, we email you a code to confirm your address.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: SignupColors.body),
          ),
        ],
      ),
    );
  }
}

class _ViewModel {
  const _ViewModel({
    required this.isLoading,
    this.errorMessage,
    this.signupEmail,
  });

  factory _ViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _ViewModel(
      isLoading: auth.isLoading,
      errorMessage: auth.errorMessage,
      signupEmail: auth.signupEmail,
    );
  }

  final bool isLoading;
  final String? errorMessage;

  /// Set once registration succeeds, and the cue to move to verification.
  final String? signupEmail;
}

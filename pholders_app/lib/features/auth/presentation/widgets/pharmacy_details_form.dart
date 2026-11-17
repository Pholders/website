import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/constants/sa_locations.dart';
import '../../data/models/doctor_registration_draft.dart';
import 'signup_kit.dart';

/// Step 2 of signing up a pharmacy: its name, licence and place, on the
/// sign-up card. Submits both steps in one signup call; the backend then
/// emails a code, and the user moves on to entering it.
///
/// Shown by step 1 in its place ([SignupPanel]) when Pharmacy is chosen.
class PharmacyDetailsForm extends StatefulWidget {
  const PharmacyDetailsForm({
    super.key,
    required this.draft,
    required this.onBack,
    this.onRegistered,
    this.compact = false,
  });

  /// The personal details from step 1: the person registering it.
  final DoctorRegistrationDraft draft;

  /// Back to step 1.
  final VoidCallback onBack;

  /// The account was created and its code emailed: on to step 3. Without
  /// it, the /verify page takes over.
  final VoidCallback? onRegistered;

  /// Phones: one column.
  final bool compact;

  @override
  State<PharmacyDetailsForm> createState() => _PharmacyDetailsFormState();
}

class _PharmacyDetailsFormState extends State<PharmacyDetailsForm> {
  final _nameController = TextEditingController();
  final _licenceController = TextEditingController();
  String _province = '';
  String _city = '';

  /// Set once Create account has been pressed: from then on each field says
  /// what is wrong with it as it is corrected.
  bool _tried = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licenceController.dispose();
    super.dispose();
  }

  String? get _nameProblem =>
      _nameController.text.trim().isEmpty ? 'Enter the pharmacy\'s name' : null;
  String? get _licenceProblem => _licenceController.text.trim().isEmpty
      ? 'Enter the pharmacy\'s licence number'
      : null;
  String? get _provinceProblem =>
      _province.isEmpty ? 'Choose your province' : null;
  String? get _cityProblem => _city.isEmpty ? 'Choose your city' : null;

  void _register() {
    setState(() => _tried = true);
    if ([_nameProblem, _licenceProblem, _provinceProblem, _cityProblem]
        .any((p) => p != null)) {
      return;
    }
    final d = widget.draft;
    StoreProvider.of<AppState>(context).dispatch(
      PharmacySignupRequestAction(
        pharmacyName: _nameController.text.trim(),
        firstName: d.firstName,
        lastName: d.lastName,
        email: d.email,
        phone: d.phone,
        password: d.password,
        licenseNumber: _licenceController.text.trim(),
        city: _city,
        province: _province,
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
          const SignupProgress(step: 2, of: 3, label: 'Your pharmacy'),
          const SizedBox(height: 20),
          SignupHeading(
            title: 'Tell us about your pharmacy',
            subtitle: 'So doctors and patients know who is dispensing. '
                '${widget.draft.firstName}, one more step after this.',
            compact: compact,
          ),
          const SizedBox(height: 24),
          const SignupSectionLabel('Pharmacy'),
          const SizedBox(height: 10),
          SignupField(
            controller: _nameController,
            label: 'Pharmacy name',
            icon: Icons.local_pharmacy_outlined,
            error: shown(_nameProblem),
            onChanged: recheck,
          ),
          const SizedBox(height: 12),
          SignupField(
            controller: _licenceController,
            label: 'Licence number',
            icon: Icons.verified_outlined,
            error: shown(_licenceProblem),
            onChanged: recheck,
          ),
          const SizedBox(height: 20),
          const SignupSectionLabel('Location'),
          const SizedBox(height: 10),
          pair(
            SignupDropdown(
              label: 'Province',
              icon: Icons.map_outlined,
              value: _province,
              items: SaLocations.provinces,
              error: shown(_provinceProblem),
              onChanged: (v) => setState(() {
                _province = v;
                // The city list depends on the province.
                _city = '';
              }),
            ),
            SignupDropdown(
              label: 'City',
              disabledLabel: 'Choose a province first',
              icon: Icons.location_city_outlined,
              value: _city,
              items: SaLocations.citiesFor(_province),
              error: _province.isEmpty ? null : shown(_cityProblem),
              onChanged: (v) => setState(() => _city = v),
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
            'Next, we email you a code to activate the pharmacy\'s account.',
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

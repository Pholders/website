import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../app/app_state.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../data/models/doctor_registration_draft.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/auth_widgets.dart';

/// Doctor registration step 2 — Professional & Practice information.
///
/// Matches Figma frame "Doctor Create account 2".
class DoctorRegisterStep2Page extends StatefulWidget {
  const DoctorRegisterStep2Page({super.key, this.draft});

  /// The personal details captured on step 1. Null when the user landed here
  /// directly (a bookmark, or a refresh, which loses GoRouter's `extra`).
  final DoctorRegistrationDraft? draft;

  @override
  State<DoctorRegisterStep2Page> createState() =>
      _DoctorRegisterStep2PageState();
}

class _DoctorRegisterStep2PageState extends State<DoctorRegisterStep2Page> {
  final _clinicNameController = TextEditingController();
  final _hpcsaController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedCity = '';
  String _selectedProvince = '';
  String? _error;

  /// Validates the practice details and submits the whole registration.
  void _register() {
    final draft = widget.draft;
    if (draft == null) return;

    final clinicName = _clinicNameController.text.trim();
    final hpcsa = _hpcsaController.text.trim();
    final specialization = _specializationController.text.trim();
    final experience = int.tryParse(_experienceController.text.trim());

    String? problem;
    if (clinicName.isEmpty) {
      problem = 'Please enter your clinic name.';
    } else if (hpcsa.isEmpty) {
      problem = 'Please enter your HPCSA number.';
    } else if (specialization.isEmpty) {
      problem = 'Please enter your specialization.';
    } else if (experience == null) {
      problem = 'Years of experience must be a number.';
    } else if (_selectedProvince.isEmpty || _selectedCity.isEmpty) {
      problem = 'Please choose your province and city.';
    }

    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);

    StoreProvider.of<AppState>(context).dispatch(
      DoctorSignupRequestAction(
        firstName: draft.firstName,
        lastName: draft.lastName,
        email: draft.email,
        phone: draft.phone,
        password: draft.password,
        hpcsaNumber: hpcsa,
        specialization: specialization,
        experience: experience!,
        clinicName: clinicName,
        city: _selectedCity,
        province: _selectedProvince,
        // The backend geocodes this field and only resolves place names, so
        // the chosen city doubles as the practice address.
        clinicAddress: _selectedCity,
      ),
    );
  }

  static const Map<String, List<String>> _citiesByProvince = {
    'Eastern Cape': ['Bhisho', 'East London', 'Gqeberha', 'Mthatha'],
    'Free State': ['Bethlehem', 'Bloemfontein', 'Welkom'],
    'Gauteng': ['Centurion', 'Johannesburg', 'Pretoria', 'Soweto'],
    'KwaZulu-Natal': [
      'Durban',
      'Newcastle',
      'Pietermaritzburg',
      'Richards Bay'
    ],
    'Limpopo': ['Polokwane', 'Thohoyandou', 'Tzaneen'],
    'Mpumalanga': ['Emalahleni', 'Mbombela', 'Secunda'],
    'North West': ['Klerksdorp', 'Mahikeng', 'Potchefstroom', 'Rustenburg'],
    'Northern Cape': ['Kimberley', 'Kuruman', 'Upington'],
    'Western Cape': ['Cape Town', 'George', 'Paarl', 'Stellenbosch'],
  };

    List<String> get _cityOptions => _selectedProvince.isEmpty
      ? const []
      : _citiesByProvince[_selectedProvince]!;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _hpcsaController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Step 1's details arrive via GoRouter's `extra`, which does not survive a
    // refresh. Send the user back rather than submitting half a form.
    if (widget.draft == null) return const _MissingDraftNotice();

    return StoreConnector<AppState, _Step2ViewModel>(
      converter: _Step2ViewModel.fromStore,
      onWillChange: (previous, next) {
        if (previous?.signupEmail == null && next.signupEmail != null) {
          context.go(AppRoutes.verifyAccount);
        }
      },
      builder: _buildForm,
    );
  }

  Widget _buildForm(BuildContext context, _Step2ViewModel vm) {
    final size = MediaQuery.sizeOf(context);
    final semiCircleWidth = size.width < 760
        ? (size.width - 32).clamp(0.0, 720.0)
        : (size.width * 0.62).clamp(0.0, 720.0);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: SingleChildScrollView(
        child: SizedBox(
          width: size.width,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: size.width < 760 ? 16 : 60,
                  right: size.width < 760 ? 16 : 60,
                ),
                child: PublicNavbar(
                  actionLabel: 'Login',
                  actionRoute: AppRoutes.login,
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
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

              // Quote icon + description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/inverted-commas-icon.png',
                        width: 24, height: 24),
                    const SizedBox(height: 4),
                    const Text(
                      'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),

              // ── Semi-circle with form ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Semi-circle
                      Container(
                        width: semiCircleWidth > 720 ? 720 : semiCircleWidth,
                        padding: EdgeInsets.only(
                          top: 80,
                          left: semiCircleWidth * 0.08,
                          right: semiCircleWidth * 0.08,
                          bottom: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF309CA3),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(500),
                            topRight: Radius.circular(500),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
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
                                  fontSize: 11, color: Colors.black54),
                            ),
                            const SizedBox(height: 16),

                            // Professional Information
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Professional Information',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                            ),
                            const SizedBox(height: 8),
                            AuthFieldPair(
                              first: _Field(
                                  controller: _clinicNameController,
                                  hint: 'Clinic Name'),
                              second: _Field(
                                  controller: _hpcsaController,
                                  hint: 'HPCSA Number'),
                            ),
                            const SizedBox(height: 8),
                            AuthFieldPair(
                              first: _Field(
                                  controller: _specializationController,
                                  hint: 'Specialization'),
                              second: _Field(
                                  controller: _experienceController,
                                  hint: 'Years of Experience'),
                            ),
                            const SizedBox(height: 14),

                            // Practice Information
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Practice Information',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                            ),
                            const SizedBox(height: 8),
                            AuthFieldPair(
                              first: _DropdownField(
                                hint: 'Province',
                                value: _selectedProvince,
                                items: _citiesByProvince.keys.toList(),
                                onChanged: (province) => setState(() {
                                  _selectedProvince = province;
                                  _selectedCity = '';
                                }),
                              ),
                              second: _DropdownField(
                                hint: 'City',
                                disabledHint: 'Select a province first',
                                value: _selectedCity,
                                items: _cityOptions,
                                onChanged: (city) =>
                                    setState(() => _selectedCity = city),
                              ),
                            ),
                            if (_error != null || vm.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error ?? vm.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB3261E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Dots centered
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.4))),
                                const SizedBox(width: 6),
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF6DD0D8))),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Back + Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back button
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.register),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5C5F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.arrow_back,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                                // Register button
                                GestureDetector(
                                  onTap: vm.isLoading ? null : _register,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5C5F).withValues(
                                          alpha: vm.isLoading ? 0.6 : 1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: vm.isLoading
                                        ? const SizedBox(
                                            width: 58,
                                            height: 17,
                                            child: Center(
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Register',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Mascot inside the semi-circle
                      Positioned(
                        top: -5,
                        child: Image.asset('assets/pill-icon.png',
                            width: 75, height: 75),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Store bindings ------------------------------------------------------------

class _Step2ViewModel {
  const _Step2ViewModel({
    required this.isLoading,
    this.errorMessage,
    this.signupEmail,
  });

  factory _Step2ViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _Step2ViewModel(
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

/// Shown when step 2 is opened without step 1's details.
class _MissingDraftNotice extends StatelessWidget {
  const _MissingDraftNotice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start from the beginning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personal details were not carried over.\nPlease fill in step 1 again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Back to registration'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {

  const _Field({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Dropdown field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.disabledHint,
  });

  final String hint;

  /// The current selection, or '' when nothing is chosen yet.
  final String value;

  /// The options to offer. Empty disables the field.
  final List<String> items;
  final ValueChanged<String> onChanged;

  /// Shown instead of [hint] when there is nothing to choose from yet.
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final enabled = items.isNotEmpty;
    // DropdownButton asserts if `value` is not among its items, which happens
    // for a moment after the province changes and clears the city.
    final selected = items.contains(value) ? value : null;

    return Container(
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 280,
          borderRadius: BorderRadius.circular(6),
          hint: Text(
            enabled ? hint : (disabledHint ?? hint),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black38),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: [
            for (final item in items)
              DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
        ),
      ),
    );
  }
}

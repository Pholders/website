import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/data/models/signup_session.dart';
import '../../../shared/constants/south_african_locations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

/// Doctor registration step 2 — Professional & Practice information.
///
/// Matches Figma frame "Doctor Create account 2".
class DoctorRegisterStep2Page extends StatefulWidget {
  const DoctorRegisterStep2Page({super.key});

  @override
  State<DoctorRegisterStep2Page> createState() => _DoctorRegisterStep2PageState();
}

class _DoctorRegisterStep2PageState extends State<DoctorRegisterStep2Page> {
  final _clinicNameController = TextEditingController();
  final _hpcsaController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedCity = '';
  String _selectedProvince = '';
  bool _isLoading = false;

  List<String> get _availableCities =>
      _selectedProvince.isEmpty
          ? <String>[]
          : SouthAfricanLocations.citiesByProvince[_selectedProvince] ?? <String>[];

  @override
  void dispose() {
    _clinicNameController.dispose();
    _hpcsaController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final session = SignupSession();

    // SignupSession lives in memory only, so a browser refresh on this page
    // wipes step 1 and we would post a payload of nulls.
    if (session.email == null ||
        session.password == null ||
        session.firstName == null ||
        session.lastName == null ||
        session.phone == null) {
      _showMessage('Your details were lost. Please start registration again.');
      context.go(AppRoutes.register);
      return;
    }

    if (_hpcsaController.text.trim().isEmpty ||
        _specializationController.text.trim().isEmpty ||
        _clinicNameController.text.trim().isEmpty ||
        _selectedCity.isEmpty ||
        _selectedProvince.isEmpty) {
      _showMessage('Please fill in all professional and practice fields.');
      return;
    }

    // The API checks `!experience`, so 0 is rejected as a missing field.
    final experience = int.tryParse(_experienceController.text.trim()) ?? 0;
    if (experience < 1) {
      _showMessage('Years of experience must be a whole number of 1 or more.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // The API expects snake_case. `clinic_address` is geocoded through a
      // place-name lookup that fails on street addresses, so send the city.
      final payload = {
        'first_name': session.firstName,
        'last_name': session.lastName,
        'email': session.email,
        'phone': session.phone,
        'password': session.password,
        'hpcsa_number': _hpcsaController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'experience': experience,
        'clinic_name': _clinicNameController.text.trim(),
        'city': _selectedCity,
        'province': _selectedProvince,
        'clinic_address': _selectedCity,
      };

      await sl<ApiClient>().dio.post('/users/doctor/signup', data: payload);

      if (!mounted) return;
      // Doctor accounts are active on signup — there is no email verification
      // step. The OTP challenge happens during login instead.
      SignupSession().clear();
      _showMessage('Account created. Please log in.');
      context.go(AppRoutes.login);
    } catch (e) {
      _showMessage(
        apiErrorMessage(e, fallback: 'Registration failed. Please try again.'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            // ── Navbar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 60, right: 60),
              child: PublicNavbar(
                actionLabel: 'Login',
                actionRoute: AppRoutes.login,
              ),
            ),
            const SizedBox(height: 24),

            // ── Hero text ────────────────────────────────────────────────
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
                  Image.asset('assets/inverted-commas-icon.png', width: 24, height: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),

            // ── Semi-circle with form ────────────────────────────────────
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Semi-circle
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
                      child: Column(
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
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 14),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Professional Information
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Professional Information',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(child: _Field(controller: _clinicNameController, hint: 'Clinic Name')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _Field(controller: _hpcsaController, hint: 'HPCSA Number')),
                                  ]),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(child: _Field(controller: _specializationController, hint: 'Specialization')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _Field(controller: _experienceController, hint: 'Years of Experience')),
                                  ]),
                                  const SizedBox(height: 12),

                                  // Practice Information
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Practice Information',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                      child: _DropdownField(
                                        hint: 'City',
                                        value: _selectedCity,
                                        items: _availableCities,
                                        onChanged: (v) => setState(() => _selectedCity = v ?? ''),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _DropdownField(
                                        hint: 'Province',
                                        value: _selectedProvince,
                                        items: SouthAfricanLocations.provinces,
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedProvince = v ?? '';
                                            _selectedCity = '';
                                          });
                                        },
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 14),
                                ],
                              ),
                            ),
                          ),

                          // Dots centered
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.4))),
                              const SizedBox(width: 6),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6DD0D8))),
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
                                  child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                                ),
                              ),
                              // Register button
                              GestureDetector(
                                onTap: _isLoading ? null : _submit,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A5C5F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
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
                      child: Image.asset('assets/pill-icon.png', width: 75, height: 75),
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

// ─── Form field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Field({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
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
  final String hint;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
          value: value.isEmpty ? null : value,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

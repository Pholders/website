import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/auth_widgets.dart';

/// Doctor registration step 2 — Professional & Practice information.
///
/// Matches Figma frame "Doctor Create account 2".
class DoctorRegisterStep2Page extends StatefulWidget {
  const DoctorRegisterStep2Page({super.key});

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
      ? (_citiesByProvince.values.expand((cities) => cities).toList()..sort())
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
              // ── Navbar ────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(
                    top: 20,
                    left: size.width < 760 ? 16 : 60,
                    right: size.width < 760 ? 16 : 60),
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
                                hint: 'City',
                                value: _selectedCity,
                                options: _cityOptions,
                                onChanged: (city) => setState(() {
                                  _selectedCity = city;
                                  _selectedProvince = _citiesByProvince.entries
                                      .firstWhere(
                                          (entry) => entry.value.contains(city))
                                      .key;
                                }),
                              ),
                              second: _DropdownField(
                                hint: 'Province',
                                value: _selectedProvince,
                                options: _citiesByProvince.keys.toList(),
                                onChanged: (province) => setState(() {
                                  _selectedProvince = province;
                                  if (!_citiesByProvince[province]!
                                      .contains(_selectedCity)) {
                                    _selectedCity = '';
                                  }
                                }),
                              ),
                            ),
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
                                  onTap: () {
                                    context.go(AppRoutes.verifyAccount);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5C5F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
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

// ─── Form field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Field({required this.controller, required this.hint});

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
  final String hint;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownField(
      {required this.hint,
      required this.value,
      required this.options,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 280,
          borderRadius: BorderRadius.circular(6),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Colors.black38),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (selection) {
            if (selection != null) onChanged(selection);
          },
        ),
      ),
    );
  }
}

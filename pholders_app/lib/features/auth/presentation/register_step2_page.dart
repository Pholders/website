import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/constants/sa_locations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

/// Doctor Create Account Step 2 - Professional & Practice Information.
class RegisterStep2Page extends StatefulWidget {
  const RegisterStep2Page({super.key});

  @override
  State<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

class _RegisterStep2PageState extends State<RegisterStep2Page> {
  final _clinicNameController = TextEditingController();
  final _hpcsaController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedCity = '';
  String _selectedProvince = '';

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
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 60, right: 60),
              child: PublicNavbar(
                actionLabel: 'Login',
                actionRoute: AppRoutes.login,
              ),
            ),
            const SizedBox(height: 24),

            // Hero text
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
                            style:
                                TextStyle(fontSize: 11, color: Colors.black54),
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
                          Row(children: [
                            Expanded(
                                child: _Field(
                                    controller: _clinicNameController,
                                    hint: 'Clinic Name')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _Field(
                                    controller: _hpcsaController,
                                    hint: 'HPCSA Number')),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: _Field(
                                    controller: _specializationController,
                                    hint: 'Specialization')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _Field(
                                    controller: _experienceController,
                                    hint: 'Years of Experience')),
                          ]),
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
                          Row(children: [
                            Expanded(
                              child: _DropdownField(
                                hint: 'Province',
                                value: _selectedProvince,
                                items: SaLocations.provinces,
                                onChanged: (v) => setState(() {
                                  _selectedProvince = v;
                                  // The city list depends on the province, so a
                                  // city picked under the previous one must not
                                  // survive the change.
                                  _selectedCity = '';
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropdownField(
                                hint: 'City',
                                disabledHint: 'Select a province first',
                                value: _selectedCity,
                                items: SaLocations.citiesFor(_selectedProvince),
                                onChanged: (v) =>
                                    setState(() => _selectedCity = v),
                              ),
                            ),
                          ]),
                          const Spacer(),

                          // Dots centered
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.4))),
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
                                onTap: () =>
                                    context.go(AppRoutes.verifyAccount),
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
                      top: 12,
                      child: Image.asset('assets/PHolders-icon.png',
                          width: 55, height: 55),
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
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Colors.black38),
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

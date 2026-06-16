import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

/// Pharmacy registration step 2 — Pharmacy & Location information.
///
/// Matches SRS FR-G-048: pharmacist registration number, pharmacy name,
/// pharmacy practice number, responsible pharmacist name, location.
class PharmacyRegisterStep2Page extends StatefulWidget {
  const PharmacyRegisterStep2Page({super.key});

  @override
  State<PharmacyRegisterStep2Page> createState() => _PharmacyRegisterStep2PageState();
}

class _PharmacyRegisterStep2PageState extends State<PharmacyRegisterStep2Page> {
  final _pharmacyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _responsiblePharmacistController = TextEditingController();
  final _streetAddressController = TextEditingController();
  String _selectedCity = '';
  String _selectedProvince = '';

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _responsiblePharmacistController.dispose();
    _streetAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final semiCircleHeight = size.height * 0.62;
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
                          const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Join the platform to manage patients, prescriptions, and consultations securely.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),

                          // Pharmacy Information
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Pharmacy Information',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: _Field(controller: _pharmacyNameController, hint: 'Pharmacy Name')),
                            const SizedBox(width: 10),
                            Expanded(child: _Field(controller: _licenseNumberController, hint: 'License Number')),
                          ]),
                          const SizedBox(height: 6),
                          _Field(controller: _responsiblePharmacistController, hint: 'Responsible Pharmacist Name'),
                          const SizedBox(height: 10),

                          // Location
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Location',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                          ),
                          const SizedBox(height: 6),
                          _Field(controller: _streetAddressController, hint: 'Street Address'),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: _DropdownField(hint: 'City', value: _selectedCity, onChanged: (v) => setState(() => _selectedCity = v))),
                            const SizedBox(width: 10),
                            Expanded(child: _DropdownField(hint: 'Province', value: _selectedProvince, onChanged: (v) => setState(() => _selectedProvince = v))),
                          ]),
                          const SizedBox(height: 14),

                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.4))),
                              const SizedBox(width: 6),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6DD0D8))),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Back + Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.go(AppRoutes.register),
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: const Color(0xFF1A5C5F), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go(AppRoutes.verifyAccount),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF1A5C5F), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ],
                          ),
                        ],
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

// ─── Reusable field widgets ──────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;

  const _Field({required this.controller, required this.hint, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
          prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.black38) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _DropdownField({required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(fontSize: 12, color: value.isEmpty ? Colors.black45 : Colors.black87),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/public_navbar.dart';

// Provinces used for the practice location dropdown
const List<String> kProvinces = [
  'Gauteng',
  'Mpumalanga',
  'North West',
  'Eastern Cape',
  'Western Cape',
  'Limpopo',
  'Kwa-Zulu Natal',
];

// Major cities/towns per province (not exhaustive)
const Map<String, List<String>> kProvinceCities = {
  'Gauteng': [
    'Johannesburg',
    'Pretoria',
    'Soweto',
    'Sandton',
    'Centurion',
    'Midrand',
    'Boksburg',
    'Benoni',
  ],
  'Mpumalanga': [
    'Mbombela',
    'Middelburg',
    'Emalahleni',
    'Secunda',
    'Ermelo',
    'Barberton',
    'White River',
  ],
  'North West': [
    'Mahikeng',
    'Rustenburg',
    'Potchefstroom',
    'Klerksdorp',
    'Brits',
    'Zeerust',
  ],
  'Eastern Cape': [
    'Gqeberha',
    'East London',
    'Mthatha',
    'Makhanda',
    'Bhisho',
    'Kariega',
  ],
  'Western Cape': [
    'Cape Town',
    'Stellenbosch',
    'Paarl',
    'Somerset West',
    'Worcester',
    'George',
    'Mossel Bay',
  ],
  'Limpopo': [
    'Polokwane',
    'Tzaneen',
    'Mokopane',
    'Thohoyandou',
    'Phalaborwa',
    'Musina',
  ],
  'Kwa-Zulu Natal': [
    'Durban',
    'Pietermaritzburg',
    'Newcastle',
    'Richards Bay',
    'Empangeni',
    'Pinetown',
    'Ladysmith',
  ],
};

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
                  Image.asset('assets/icons/inverted-commas-icon.png', width: 24, height: 24),
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
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),

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
                          const SizedBox(height: 14),

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
                                items: kProvinceCities[_selectedProvince] ?? [],
                                onChanged: (v) => setState(() => _selectedCity = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropdownField(
                                hint: 'Province',
                                value: _selectedProvince,
                                onChanged: (v) => setState(() {
                                  _selectedProvince = v;
                                  _selectedCity = '';
                                }),
                              ),
                            ),
                          ]),
                          const Spacer(),

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
                                onTap: () => context.go(AppRoutes.verifyAccount),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A5C5F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
                      child: Image.asset('assets/icons/PHolders-icon.png', width: 55, height: 55),
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

  const _DropdownField({required this.hint, required this.value, required this.onChanged, this.items});
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String>? items;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () async {
          final list = items ?? kProvinces;
          if (list.isEmpty) {
            // Prompt user to choose a province first
            await showModalBottomSheet<void>(
              context: context,
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Please select a province first.', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                    ],
                  ),
                ),
              ),
            );
            return;
          }

          final selected = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: list
                    .map(
                      (p) => ListTile(
                        title: Text(p),
                        onTap: () => Navigator.of(ctx).pop(p),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
          if (selected != null) onChanged(selected);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(fontSize: 12, color: value.isEmpty ? Colors.black38 : Colors.black87),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

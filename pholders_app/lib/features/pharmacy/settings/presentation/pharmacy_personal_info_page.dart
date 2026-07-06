import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Personal Information page — extracted from Profile for better UX.
class PharmacyPersonalInfoPage extends StatefulWidget {
  const PharmacyPersonalInfoPage({super.key});

  @override
  State<PharmacyPersonalInfoPage> createState() => _PharmacyPersonalInfoPageState();
}

class _PharmacyPersonalInfoPageState extends State<PharmacyPersonalInfoPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  final _usernameC = TextEditingController(text: 'sampharmacy');
  final _firstNameC = TextEditingController(text: 'Sam');
  final _surnameC = TextEditingController(text: 'Mashumu');
  final _emailC = TextEditingController(text: 'sam@pholderspharmacy.co.za');
  final _mobileC = TextEditingController(text: '+27 82 123 4567');
  final _currentPasswordC = TextEditingController();
  final _newPasswordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();
  String _gender = 'Male';
  Uint8List? _profilePhoto;

  @override
  void dispose() {
    _usernameC.dispose();
    _firstNameC.dispose();
    _surnameC.dispose();
    _emailC.dispose();
    _mobileC.dispose();
    _currentPasswordC.dispose();
    _newPasswordC.dispose();
    _confirmPasswordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(selectedItemId: 'personal_information', onMenuItemSelected: (id) => _navigate(context, id)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: _tealBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 24),
                      // Profile photo
                      Center(child: Column(children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: const Color(0x33309CA3),
                            border: Border.all(color: _teal, width: 2),
                            image: _profilePhoto != null
                                ? DecorationImage(image: MemoryImage(_profilePhoto!), fit: BoxFit.cover)
                                : const DecorationImage(image: AssetImage('assets/doctors.png'), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _tealBorder)),
                            child: const Text('Upload Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _teal)),
                          ),
                        ),
                      ])),
                      const SizedBox(height: 28),
                      _field('Username', _usernameC),
                      _field('First Name', _firstNameC),
                      _field('Surname', _surnameC),
                      _field('Email', _emailC),
                      _field('Mobile', _mobileC),
                      _dropdown('Gender', _gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v)),
                      const SizedBox(height: 20),
                      const Text('Change Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      _field('Current Password', _currentPasswordC, obscure: true),
                      _field('New Password', _newPasswordC, obscure: true),
                      _field('Confirm Password', _confirmPasswordC, obscure: true),
                      const SizedBox(height: 20),
                      _saveButton(),
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

  Widget _header() => Row(children: [
    const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
    const Spacer(),
    InkWell(onTap: _save, borderRadius: BorderRadius.circular(25), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: _tealBorder, borderRadius: BorderRadius.circular(25)),
      child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    )),
  ]);

  Widget _field(String label, TextEditingController c, {bool obscure = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: _textMuted))),
      Expanded(child: TextField(controller: c, obscureText: obscure, style: const TextStyle(fontSize: 13, color: _textDark), decoration: InputDecoration(filled: true, fillColor: _fieldBg, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
    ]),
  );

  Widget _dropdown(String label, String value, List<String> opts, ValueChanged<String> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: _textMuted))),
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, style: const TextStyle(fontSize: 13, color: _textDark), items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(), onChanged: (v) { if (v != null) onChanged(v); })))),
    ]),
  );

  Widget _saveButton() => Align(alignment: Alignment.centerRight, child: InkWell(onTap: _save, borderRadius: BorderRadius.circular(25), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(25)), child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)))));

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) setState(() => _profilePhoto = result.files.single.bytes);
  }

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Personal information saved'), backgroundColor: Color(0xFF309CA3), behavior: SnackBarBehavior.floating));

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information': context.go(AppRoutes.pharmacySettingsPersonalInfo); break;
      case 'pharmacy_details': context.go(AppRoutes.pharmacySettingsPharmacyDetails); break;
      case 'professional': context.go(AppRoutes.pharmacySettingsProfessional); break;
      case 'notification_settings':
      case 'preferences_notifications':
        context.go(AppRoutes.pharmacySettingsNotifications);
        break;
      case 'notification_center':
        context.go(AppRoutes.pharmacySettingsNotificationCenter);
        break;
      case 'linked_services': context.go(AppRoutes.pharmacySettingsLinkedServices); break;
      default: break;
    }
  }
}

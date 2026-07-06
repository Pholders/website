import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Pharmacist Profile page — Full details form (SRS FR-G-051, FR-G-052).
///
/// Fields: username, mobile, email, first name, surname, pharmacist registration
/// number, pharmacy name, pharmacy practice number, logo, profile picture, gender.
class PharmacyProfilePage extends StatefulWidget {
  const PharmacyProfilePage({super.key});

  @override
  State<PharmacyProfilePage> createState() => _PharmacyProfilePageState();
}

class _PharmacyProfilePageState extends State<PharmacyProfilePage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  // Controllers
  final _usernameC = TextEditingController(text: 'sampharmacy');
  final _firstNameC = TextEditingController(text: 'Sam');
  final _surnameC = TextEditingController(text: 'Mashumu');
  final _emailC = TextEditingController(text: 'sam@pholderspharmacy.co.za');
  final _mobileC = TextEditingController(text: '+27 82 123 4567');
  final _regNumberC = TextEditingController(text: 'PH-2024-09876');
  final _pharmacyNameC = TextEditingController(text: 'Pholders Pharmacy');
  final _practiceNumberC = TextEditingController(text: 'Y-12345');
  String _gender = 'Male';
  Uint8List? _profilePhoto;
  Uint8List? _logoPhoto;

  @override
  void dispose() {
    _usernameC.dispose();
    _firstNameC.dispose();
    _surnameC.dispose();
    _emailC.dispose();
    _mobileC.dispose();
    _regNumberC.dispose();
    _pharmacyNameC.dispose();
    _practiceNumberC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(
            selectedItemId: 'profile',
            onMenuItemSelected: (_) {},
          ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: _tealBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(color: Color(0x33309CA3), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back, size: 16, color: _teal),
                          ),
                          const SizedBox(width: 12),
                          const Text('Pharmacy Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                          const Spacer(),
                          InkWell(
                            onTap: _saveProfile,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(color: _tealBorder, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.black.withValues(alpha: 0.1))),
                              child: const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 20),

                      // Profile photo + upload
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x33309CA3),
                                border: Border.all(color: _teal, width: 2),
                                image: _profilePhoto != null
                                    ? DecorationImage(image: MemoryImage(_profilePhoto!), fit: BoxFit.cover)
                                    : const DecorationImage(image: AssetImage('assets/doctors.png'), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _pickProfilePhoto,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _tealBorder)),
                                child: const Text('Upload Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _teal)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Personal Information
                      _sectionTitle('Personal Information'),
                      const SizedBox(height: 12),
                      _fieldRow('Username', _usernameC),
                      _fieldRow('First Name', _firstNameC),
                      _fieldRow('Surname', _surnameC),
                      _fieldRow('Email', _emailC),
                      _fieldRow('Mobile', _mobileC),
                      _dropdownRow('Gender', _gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v)),
                      const SizedBox(height: 24),

                      // Pharmacy Details
                      _sectionTitle('Pharmacy Details'),
                      const SizedBox(height: 12),
                      _fieldRow('Pharmacy Name', _pharmacyNameC),
                      _fieldRow('Registration No.', _regNumberC),
                      _fieldRow('Practice Number', _practiceNumberC),
                      const SizedBox(height: 24),

                      // Logo upload
                      _sectionTitle('Pharmacy Logo'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 120, height: 80,
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            image: _logoPhoto != null
                                ? DecorationImage(image: MemoryImage(_logoPhoto!), fit: BoxFit.contain)
                                : null,
                          ),
                          child: _logoPhoto == null
                              ? const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 28, color: _teal))
                              : null,
                        ),
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

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark));
  }

  Widget _fieldRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: _textMuted))),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: _fieldBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: _textMuted))),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: _textDark),
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _profilePhoto = result.files.single.bytes);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _logoPhoto = result.files.single.bytes);
    }
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✓ Profile saved'),
      backgroundColor: Color(0xFF309CA3),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

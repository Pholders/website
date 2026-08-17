import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Pharmacy Details page — pharmacy-specific information.
class PharmacyDetailsPage extends StatefulWidget {
  const PharmacyDetailsPage({super.key});

  @override
  State<PharmacyDetailsPage> createState() => _PharmacyDetailsPageState();
}

class _PharmacyDetailsPageState extends State<PharmacyDetailsPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  final _pharmacyNameC = TextEditingController(text: 'Pholders Pharmacy');
  final _regNumberC = TextEditingController(text: 'PH-2024-09876');
  final _practiceNumberC = TextEditingController(text: 'Y-12345');
  final _addressC = TextEditingController(text: '123 Main Road, Sandton');
  final _cityC = TextEditingController(text: 'Johannesburg');
  final _provinceC = TextEditingController(text: 'Gauteng');
  final _postalCodeC = TextEditingController(text: '2196');
  Uint8List? _logo;

  @override
  void dispose() {
    _pharmacyNameC.dispose();
    _regNumberC.dispose();
    _practiceNumberC.dispose();
    _addressC.dispose();
    _cityC.dispose();
    _provinceC.dispose();
    _postalCodeC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(selectedItemId: 'pharmacy_details', onMenuItemSelected: (id) => _nav(context, id)),
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
                      Row(children: [
                        const Text('Pharmacy Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                        const Spacer(),
                        InkWell(onTap: _save, borderRadius: BorderRadius.circular(25), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: _tealBorder, borderRadius: BorderRadius.circular(25)), child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)))),
                      ]),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 24),
                      _field('Pharmacy Name', _pharmacyNameC),
                      _field('Registration No.', _regNumberC),
                      _field('Practice Number', _practiceNumberC),
                      const SizedBox(height: 20),
                      const Text('Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      _field('Street Address', _addressC),
                      _field('City', _cityC),
                      _field('Province', _provinceC),
                      _field('Postal Code', _postalCodeC),
                      const SizedBox(height: 20),
                      const Text('Pharmacy Logo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140, height: 90,
                          decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB)),
                            image: _logo != null ? DecorationImage(image: MemoryImage(_logo!), fit: BoxFit.contain) : null),
                          child: _logo == null ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_outlined, size: 28, color: _teal), SizedBox(height: 4), Text('Upload Logo', style: TextStyle(fontSize: 10, color: _teal))])) : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(alignment: Alignment.centerRight, child: InkWell(onTap: _save, borderRadius: BorderRadius.circular(25), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(25)), child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))))),
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

  Widget _field(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: _textMuted))),
      Expanded(child: TextField(controller: c, style: const TextStyle(fontSize: 13, color: _textDark), decoration: InputDecoration(filled: true, fillColor: _fieldBg, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
    ]),
  );

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) setState(() => _logo = result.files.single.bytes);
  }

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Pharmacy details saved'), backgroundColor: Color(0xFF309CA3), behavior: SnackBarBehavior.floating));

  void _nav(BuildContext context, String id) {
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

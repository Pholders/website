import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Professional Details page — qualifications, operating hours, responsible pharmacist.
class PharmacyProfessionalPage extends StatefulWidget {
  const PharmacyProfessionalPage({super.key});

  @override
  State<PharmacyProfessionalPage> createState() => _PharmacyProfessionalPageState();
}

class _PharmacyProfessionalPageState extends State<PharmacyProfessionalPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  final _responsiblePharmacistC = TextEditingController(text: 'Sam Mashumu');
  final _sapcRegC = TextEditingController(text: 'SAPC-Y12345');
  final _qualificationC = TextEditingController(text: 'BPharm (University of Pretoria)');
  final _experienceC = TextEditingController(text: '8 years');
  final _weekdayHoursC = TextEditingController(text: '08:00 - 18:00');
  final _saturdayHoursC = TextEditingController(text: '08:00 - 13:00');
  final _sundayHoursC = TextEditingController(text: 'Closed');

  @override
  void dispose() {
    _responsiblePharmacistC.dispose();
    _sapcRegC.dispose();
    _qualificationC.dispose();
    _experienceC.dispose();
    _weekdayHoursC.dispose();
    _saturdayHoursC.dispose();
    _sundayHoursC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(selectedItemId: 'professional', onMenuItemSelected: (id) => _nav(context, id)),
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
                        const Text('Professional Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                        const Spacer(),
                        InkWell(onTap: _save, borderRadius: BorderRadius.circular(25), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: _tealBorder, borderRadius: BorderRadius.circular(25)), child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)))),
                      ]),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 24),
                      const Text('Responsible Pharmacist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      _field('Name', _responsiblePharmacistC),
                      _field('SAPC Reg No.', _sapcRegC),
                      _field('Qualification', _qualificationC),
                      _field('Experience', _experienceC),
                      const SizedBox(height: 20),
                      const Text('Operating Hours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 12),
                      _field('Mon - Fri', _weekdayHoursC),
                      _field('Saturday', _saturdayHoursC),
                      _field('Sunday', _sundayHoursC),
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

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Professional details saved'), backgroundColor: Color(0xFF309CA3), behavior: SnackBarBehavior.floating));

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

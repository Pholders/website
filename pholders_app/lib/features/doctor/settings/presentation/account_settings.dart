import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../auth/data/models/doctor.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return initialTab == 1
        ? const _ProfessionalDetails()
        : const _ProfileDetails();
  }

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go(AppRoutes.doctorSettingsProfile);
        break;
      case 'professional':
        context.go(AppRoutes.doctorSettingsProfessional);
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPractice);
        break;
      case 'notification_settings':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=1');
        break;
      case 'notification_center':
        context.go(AppRoutes.doctorNotifications);
        break;
      case 'security_settings':
        context.go(AppRoutes.doctorSettingsSecurity);
        break;
      case 'device_management':
        context.go(AppRoutes.doctorSettingsDevices);
        break;
      case 'login_activity':
        context.go(AppRoutes.doctorSettingsLoginActivity);
        break;
      case 'preferences_settings':
        context.go(AppRoutes.doctorSettingsPreferences);
        break;
      case 'linked_services':
        context.go(AppRoutes.doctorSettingsLinkedServices);
        break;
      case 'help_center':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=0');
        break;
      case 'privacy_policy':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=1');
        break;
      case 'terms_of_service':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=2');
        break;
      case 'contact_support':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=3');
        break;
      default:
        break;
    }
  }
}

class _ProfileDetails extends StatefulWidget {
  const _ProfileDetails();

  @override
  State<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<_ProfileDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'personal_information',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Profile Details',
                children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 9,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(110),
                    child: Image.asset(
                      'assets/doctors.png',
                      width: 190,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsButton(
  'Upload photo',
  onTap: () async {
    await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
  },
),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 22),
                      child: Text('About', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 154,
                    margin: const EdgeInsets.only(right: 18),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: SettingsShell.panelMint,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCFECEE)),
                    ),
                    child: const Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Write a Bio about yourself for patients\nto know your background',
                            style: TextStyle(
                                fontSize: 12, color: SettingsShell.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                        const SizedBox(width: 26),
            const Expanded(
              flex: 12,
              child: _ProfileForm(),
            ),
          ],
        ),
      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go(AppRoutes.doctorSettingsProfile);
        break;
      case 'professional':
        context.go(AppRoutes.doctorSettingsProfessional);
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPractice);
        break;
      case 'notification_settings':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=1');
        break;
      case 'notification_center':
        context.go(AppRoutes.doctorNotifications);
        break;
      case 'security_settings':
        context.go(AppRoutes.doctorSettingsSecurity);
        break;
      case 'device_management':
        context.go(AppRoutes.doctorSettingsDevices);
        break;
      case 'login_activity':
        context.go(AppRoutes.doctorSettingsLoginActivity);
        break;
      case 'preferences_settings':
        context.go(AppRoutes.doctorSettingsPreferences);
        break;
      case 'linked_services':
        context.go(AppRoutes.doctorSettingsLinkedServices);
        break;
      case 'help_center':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=0');
        break;
      case 'privacy_policy':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=1');
        break;
      case 'terms_of_service':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=2');
        break;
      case 'contact_support':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=3');
        break;
      default:
        break;
    }
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm();

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  bool isEditing = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  /// True once the fields hold the loaded profile, so a later store update
  /// does not overwrite something being typed.
  bool _prefilled = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _prefill(Doctor? doctor) {
    if (doctor == null || _prefilled) return;
    _firstName.text = doctor.firstName;
    _lastName.text = doctor.lastName;
    _email.text = doctor.email;
    _phone.text = doctor.phone ?? '';
    _prefilled = true;
  }

  void _save() {
    StoreProvider.of<AppState>(context).dispatch(
      UpdateDoctorProfileAction(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProfileViewModel>(
      converter: _ProfileViewModel.fromStore,
      builder: (context, vm) {
        _prefill(vm.doctor);
        return _buildForm(context, vm);
      },
    );
  }

  Widget _buildForm(BuildContext context, _ProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Personal Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Field(label: 'First Name', controller: _firstName),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _Field(label: 'Last Name', controller: _lastName),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SettingsSectionTitle('Contact Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            // The endpoint strips email before writing, so it is shown but
            // not editable rather than silently discarded on save.
            Expanded(
              child: _Field(
                label: 'Email Address',
                controller: _email,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(child: _Field(label: 'Phone Number', hint: '0123456789',
            controller: _phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],)),
          ],
        ),
        const SizedBox(height: 26),
        const SettingsSectionTitle('Additional Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
                child: _Field(
                    label: 'Date of Birth',
                    hint: 'Select Date',
                    icon: Icons.calendar_month)),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender', 
                    style: TextStyle(fontSize: 16)
                    ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFEAF8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide (
                          color: Color(0xFFCFECEE)),
                      ),
                    ),
                  hint: const Text('Select Gender'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male'),),
                    DropdownMenuItem(value: 'female', child: Text('Female'),),
                    DropdownMenuItem(value: 'other', child: Text('Other'),),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say'),),
                  ],
                  onChanged: (value) {},
              ),
            ],
          ),
        ),
          ]),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Nationality',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('South African'),
        items: const [
          DropdownMenuItem(value: 'South African',child: Text('South African'),),
          DropdownMenuItem(value: 'Zimbabwean',child: Text('Zimbabwean'),),
          DropdownMenuItem(value: 'Botswanan',child: Text('Botswanan'),),
          DropdownMenuItem(value: 'Namibian',child: Text('Namibian'),),
          DropdownMenuItem(value: 'Mozambican',child: Text('Mozambican'),),
          DropdownMenuItem(value: 'Lesotho',child: Text('Lesotho'),),
          DropdownMenuItem(value: 'Eswatini',child: Text('Eswatini'),),
          DropdownMenuItem(value: 'Other',child: Text('Other'),),
        ],
        onChanged: (value) {},
      ),
    ],
  ),
),
            const SizedBox(width: 22),
            Expanded(child: _Field(label: 'ID Number', hint: '0123456789012', inputFormatters: [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(13)],)),
          ],
        ),
        const SizedBox(height: 26),
        if (vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              vm.errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFCC1111)),
            ),
          ),
        Align(
  alignment: Alignment.centerRight,
  child: SettingsButton(
    isEditing ? 'Save Changes' : 'Edit',
    icon: isEditing
        ? Icons.save_outlined
        : Icons.edit_outlined,
    width: 140,
    height: 34,
    onTap: vm.isSaving
        ? null
        : () {
            // Leaving edit mode is the save.
            if (isEditing) _save();
            setState(() => isEditing = !isEditing);
          },
  ),
),
      ],
    );
  }
}

class _ProfessionalDetails extends StatefulWidget {
  const _ProfessionalDetails();

  @override
  State<_ProfessionalDetails> createState() => _ProfessionalDetailsState();
}

class _ProfessionalDetailsState extends State<_ProfessionalDetails> {
  final _licenseNumber = TextEditingController();
  final _hpcsa = TextEditingController();
  final _experience = TextEditingController();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _city = TextEditingController();
  final _zipCode = TextEditingController();

  String? _specialization;
  String? _province;
  bool _prefilled = false;
  String? _problem;

  /// Catalogue ids of the schemes this doctor accepts.
  Set<int> _medicalAidIds = {};

  /// The options the screen ships with. A doctor whose stored value is not on
  /// the list keeps it — see [_specializations].
  static const _baseSpecializations = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Paediatrician',
    'Psychiatrist',
  ];

  static const _provinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
    'North West',
    'Western Cape',
  ];

  /// Existing doctors hold values this list never had — the test account is
  /// "General Practice", not "General Practitioner". Dropping it would either
  /// crash the dropdown or silently rewrite the doctor's specialization on the
  /// next save, so an unknown value is kept and offered.
  List<String> get _specializations {
    final current = _specialization;
    if (current == null || _baseSpecializations.contains(current)) {
      return _baseSpecializations;
    }
    return [current, ..._baseSpecializations];
  }

  @override
  void initState() {
    super.initState();
    // The picker needs the catalogue; it is reference data, so this is a
    // no-op after the first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context)
            .dispatch(const LoadMedicalAidCatalogueAction());
      }
    });
  }

  @override
  void dispose() {
    _licenseNumber.dispose();
    _hpcsa.dispose();
    _experience.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _city.dispose();
    _zipCode.dispose();
    super.dispose();
  }

  void _prefill(Doctor? doctor) {
    if (doctor == null || _prefilled) return;
    _hpcsa.text = doctor.hpcsaNumber ?? '';
    _experience.text = doctor.experience?.toString() ?? '';
    _clinicName.text = doctor.clinicName ?? '';
    _clinicAddress.text = doctor.clinicAddress ?? '';
    _city.text = doctor.city ?? '';
    _zipCode.text = doctor.zipCode ?? '';
    _specialization = doctor.specialization;
    _province = _provinces.contains(doctor.province) ? doctor.province : null;
    _medicalAidIds = doctor.medicalAids.map((s) => s.id).toSet();
    _prefilled = true;
  }

  void _save() {
    final experienceText = _experience.text.trim();
    final experience = experienceText.isEmpty ? null : int.tryParse(experienceText);
    if (experienceText.isNotEmpty && experience == null) {
      setState(() => _problem = 'Years of experience must be a number.');
      return;
    }
    setState(() => _problem = null);

    StoreProvider.of<AppState>(context).dispatch(
      UpdateDoctorProfileAction(
        specialization: _specialization,
        experience: experience,
        clinicName: _clinicName.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        city: _city.text.trim(),
        province: _province,
        zipCode: _zipCode.text.trim(),
        medicalAidIds: _medicalAidIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProfileViewModel>(
      converter: _ProfileViewModel.fromStore,
      builder: (context, vm) {
        _prefill(vm.doctor);
        return _buildScreen(context, vm);
      },
    );
  }

  Widget _buildScreen(BuildContext context, _ProfileViewModel vm) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'professional',
            onMenuItemSelected: (id) => const AccountSettings()._navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Professional Details',
                children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionTitle('Medical Credentials', muted: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  // No column on the doctors table, so this is not sent on
                  // save. Left visible rather than removed from their design.
                  Expanded(
                    child: _Field(
                      label: 'Medical License Number',
                      controller: _licenseNumber,
                    ),
                  ),
                  const SizedBox(width: 48),
                  // The endpoint strips hpcsa_number before writing, so an
                  // editable field would discard whatever was typed.
                  Expanded(
                    child: _Field(
                      label: 'HPCSA Number',
                      controller: _hpcsa,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Specialization',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('Select Specialization'),
        value: _specialization,
        items: [
          for (final s in _specializations)
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (value) => setState(() => _specialization = value),
      ),
    ],
  ),
),
                  const SizedBox(width: 48),
                  Expanded(
                    child: _Field(
                      label: 'Years of Experience',
                      controller: _experience,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const SettingsSectionTitle('Practice Information', muted: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Practice Name',
                      controller: _clinicName,
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: _Field(
                      label: 'Practice Address',
                      controller: _clinicAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'City',
                      hint: 'Johannesburg',
                      controller: _city,
                      trailing: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF748486)),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Province',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('Gauteng'),
        value: _province,
        items: [
          for (final p in _provinces)
            DropdownMenuItem(value: p, child: Text(p)),
        ],
        onChanged: (value) => setState(() => _province = value),
      ),
    ],
  ),
),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                  width: 210,
                  child: _Field(
                    label: 'Postal Code',
                    hint: '2001',
                    controller: _zipCode,
                  )),
              const SizedBox(height: 28),
              const SettingsSectionTitle('Medical Aids Accepted', muted: true),
              const SizedBox(height: 4),
              const Text(
                'Patients searching for a doctor covered by their plan will '
                'only see you if you accept their scheme.',
                style: TextStyle(fontSize: 12, color: Color(0xFF748486)),
              ),
              const SizedBox(height: 10),
              _MedicalAidPicker(
                catalogue: vm.medicalAidCatalogue,
                selected: _medicalAidIds,
                onChanged: (ids) => setState(() => _medicalAidIds = ids),
              ),
            ],
          ),
        ),
                const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SignatureArea(
            onSave: vm.isSaving ? null : _save,
            errorMessage: _problem ?? vm.errorMessage,
          ),
        ),
      ],
              ),
            ),
          ),
                ],
      ),
    );
  }
}

/// Lets the doctor tick the medical aid schemes they accept.
///
/// A fixed catalogue rather than free text: the patient's own scheme is free
/// text, and the two are matched on a normalised form, so free text on both
/// sides would never match reliably.
class _MedicalAidPicker extends StatelessWidget {
  const _MedicalAidPicker({
    required this.catalogue,
    required this.selected,
    required this.onChanged,
  });

  final List<MedicalAidScheme> catalogue;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (catalogue.isEmpty) {
      // Either the catalogue has not arrived yet or this backend does not
      // have it. Say so rather than showing an empty box that looks broken.
      return const Text(
        'Medical aid list unavailable.',
        style: TextStyle(fontSize: 12, color: Color(0xFF748486)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final scheme in catalogue)
          FilterChip(
            label: Text(scheme.name, style: const TextStyle(fontSize: 12)),
            selected: selected.contains(scheme.id),
            onSelected: (isOn) {
              final next = {...selected};
              if (isOn) {
                next.add(scheme.id);
              } else {
                next.remove(scheme.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _SignatureArea extends StatelessWidget {
  const _SignatureArea({this.onSave, this.errorMessage});

  /// The Save Changes button at the foot of this section saves the whole
  /// Professional Details screen, not just the signature.
  final VoidCallback? onSave;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Digital Signature', muted: true),
        const SizedBox(height: 12),
        Row(
          children: [
            const SettingsButton('Draw your signature',
                icon: Icons.draw_outlined, width: 190, filled: false),
            const SizedBox(width: 42),
            SettingsButton(
              'Upload Signature',
              onTap: () async {
                await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        const SettingsSectionTitle('Digital Preview', muted: true),
        const SizedBox(height: 16),
        const SizedBox(
          width: 110,
          height: 86,
          child: CustomPaint(painter: _SignaturePainter()),
        ),
        const SizedBox(height: 18),
        const SettingsSectionTitle('Verification Status', muted: true),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6F72),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Not Verified',
            style: TextStyle(fontSize: 11, color: Color(0xFFCC1111)),
          ),
        ),
        const SizedBox(height: 16),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111)),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: SettingsButton('Save Changes',
              width: 150, filled: false, height: 30, onTap: onSave),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.hint,
    this.icon,
    this.trailing,
    this.inputFormatters,
    this.controller,
    this.readOnly = false,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;

  /// Supplied for fields that are actually saved. Without one the field stays
  /// decorative, as it was.
  final TextEditingController? controller;

  /// True for values the backend refuses to change, so they are shown but
  /// cannot be edited.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        SettingsInput(
          hint: hint,
          icon: icon,
          trailing: trailing,
          inputFormatters: inputFormatters,
          controller: controller,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF12C7C8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final corner = Paint()
      ..color = const Color(0xFF12C7C8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(4, 4), const Offset(26, 4), corner);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 26), corner);
    canvas.drawLine(
        Offset(size.width - 4, 4), Offset(size.width - 26, 4), corner);
    canvas.drawLine(
        Offset(size.width - 4, 4), Offset(size.width - 4, 26), corner);
    canvas.drawLine(
        Offset(4, size.height - 4), Offset(26, size.height - 4), corner);
    canvas.drawLine(
        Offset(4, size.height - 4), Offset(4, size.height - 26), corner);
    canvas.drawLine(Offset(size.width - 4, size.height - 4),
        Offset(size.width - 26, size.height - 4), corner);
    canvas.drawLine(Offset(size.width - 4, size.height - 4),
        Offset(size.width - 4, size.height - 26), corner);

    final path = Path()
      ..moveTo(28, 60)
      ..cubicTo(40, 20, 40, 20, 46, 62)
      ..cubicTo(54, 45, 55, 45, 58, 65)
      ..cubicTo(66, 48, 70, 48, 78, 59)
      ..cubicTo(86, 68, 94, 54, 100, 57);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Store bindings ------------------------------------------------------------

class _ProfileViewModel {
  const _ProfileViewModel({
    required this.isSaving,
    this.doctor,
    this.errorMessage,
    this.medicalAidCatalogue = const [],
  });

  factory _ProfileViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _ProfileViewModel(
      isSaving: auth.isLoading,
      doctor: auth.doctor,
      errorMessage: auth.errorMessage,
      medicalAidCatalogue: auth.medicalAidCatalogue,
    );
  }

  final bool isSaving;
  final Doctor? doctor;
  final String? errorMessage;
  final List<MedicalAidScheme> medicalAidCatalogue;
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/network/secure_url.dart';
import '../../../auth/data/models/doctor.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/images/background_removal.dart';
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

/// Personal Information: photo, the About text patients read, name and phone.
///
/// The About box used to be a fixed hint that could not be typed in, though
/// the doctor record has a bio column and the patient app shows it ("No
/// biography provided yet."). Date of birth, gender, nationality and ID number
/// were shown switched off: nothing stores them, and the SRS asks the platform
/// to collect only what it needs (BR-107), so they are gone.
class _ProfileDetails extends StatefulWidget {
  const _ProfileDetails();

  @override
  State<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<_ProfileDetails> {
  static const bioLimit = 1000;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();

  bool _isEditing = false;
  bool _prefilled = false;

  /// Set when this screen sends a save, so the answer can be reported here.
  bool _awaitingSave = false;
  String? _problem;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Fills the fields from the stored profile: once at first, and again on
  /// Cancel. Not on every store change, so typing is never overwritten.
  void _fill(Doctor doctor) {
    _firstName.text = doctor.firstName;
    _lastName.text = doctor.lastName;
    _email.text = doctor.email;
    _phone.text = doctor.phone ?? '';
    _bio.text = doctor.bio ?? '';
  }

  String? _validate() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      return 'First and last name are both needed.';
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && phone.length != 10) {
      return 'A phone number has 10 digits, like 0821234567.';
    }
    return null;
  }

  void _save() {
    final problem = _validate();
    setState(() => _problem = problem);
    if (problem != null) return;
    _awaitingSave = true;
    StoreProvider.of<AppState>(context).dispatch(
      UpdateDoctorProfileAction(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
      ),
    );
  }

  void _cancel(Doctor? doctor) {
    if (doctor != null) _fill(doctor);
    setState(() {
      _isEditing = false;
      _problem = null;
    });
  }

  /// Reports how a save this screen sent turned out, once it has.
  void _onChange(_ProfileViewModel? previous, _ProfileViewModel vm) {
    if (!_awaitingSave || vm.isSaving) return;
    _awaitingSave = false;
    if (vm.errorMessage == null) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile is saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProfileViewModel>(
      converter: _ProfileViewModel.fromStore,
      onWillChange: _onChange,
      builder: (context, vm) {
        final doctor = vm.doctor;
        if (doctor != null && !_prefilled) {
          _fill(doctor);
          _prefilled = true;
        }
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
            selectedItemId: 'personal_information',
            onMenuItemSelected: (id) => const AccountSettings()._navigate(context, id),
          ),
          // ── Content area ──────────────────────────────────────────────────
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: _ProfilePhoto()),
                            const SizedBox(height: 14),
                            const Text('About', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            const Text(
                              'Patients read this on your page in the app.',
                              style: TextStyle(fontSize: 12, color: SettingsShell.muted),
                            ),
                            const SizedBox(height: 8),
                            _bioField(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(flex: 12, child: _form(vm)),
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

  Widget _bioField() {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: TextField(
        key: const ValueKey('bio'),
        controller: _bio,
        readOnly: !_isEditing,
        minLines: 6,
        maxLines: 10,
        maxLength: bioLimit,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Your training, the care you focus on, and languages you '
              'consult in.',
          hintStyle: const TextStyle(fontSize: 12, color: SettingsShell.muted),
          filled: true,
          fillColor: SettingsShell.panelMint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCFECEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCFECEE)),
          ),
        ),
      ),
    );
  }

  Widget _form(_ProfileViewModel vm) {
    final error = _problem ?? (_awaitingSave ? null : vm.errorMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Personal Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Field(
                  label: 'First Name', controller: _firstName, readOnly: !_isEditing),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _Field(
                  label: 'Last Name', controller: _lastName, readOnly: !_isEditing),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SettingsSectionTitle('Contact Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            // The endpoint strips email before writing, so it is shown but
            // never editable rather than silently discarded on save.
            Expanded(
              child: _Field(label: 'Email Address', controller: _email, readOnly: true),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _Field(
                label: 'Phone Number',
                hint: '0821234567',
                controller: _phone,
                readOnly: !_isEditing,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Your email is how you sign in, so it cannot be changed here.',
          style: TextStyle(fontSize: 12, color: SettingsShell.muted),
        ),
        const SizedBox(height: 26),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: const TextStyle(fontSize: 13, color: Color(0xFFCC1111))),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isEditing) ...[
              SettingsButton(
                'Cancel',
                width: 110,
                height: 34,
                filled: false,
                onTap: vm.isSaving ? null : () => _cancel(vm.doctor),
              ),
              const SizedBox(width: 12),
            ],
            SettingsButton(
              _isEditing ? (vm.isSaving ? 'Saving…' : 'Save Changes') : 'Edit',
              icon: _isEditing ? Icons.save_outlined : Icons.edit_outlined,
              width: 150,
              height: 34,
              onTap: vm.isSaving
                  ? null
                  : _isEditing
                      ? _save
                      : () => setState(() => _isEditing = true),
            ),
          ],
        ),
      ],
    );
  }
}

/// The doctor's photo, and the control that replaces it.
///
/// The picked bytes go straight to `PUT /users/doctor/profile/image`; the
/// server stores them, deletes whatever it replaced, and answers with the URL
/// the image is now served from. Nothing is held on the client.
class _ProfilePhoto extends StatefulWidget {
  const _ProfilePhoto();

  @override
  State<_ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<_ProfilePhoto> {
  /// What the server accepts. Checked here too, so an obvious mistake is
  /// answered immediately instead of after a round trip.
  static const _accepted = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };
  static const _maxBytes = 5 * 1024 * 1024;

  String? _problem;

  /// True while the background is being cut out in the browser. The first
  /// photo of a session is slow — the library and its model come down from a
  /// CDN — so this is worth saying rather than appearing to have hung.
  bool _removingBackground = false;

  /// Something that went differently but is not an error, such as the photo
  /// going up with its background still on.
  String? _note;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _accepted.keys.toList(),
      // The web has no path to read back from, so ask for the bytes.
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return;

    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _problem = 'That file could not be read. Try another one.');
      return;
    }

    final extension = (file.extension ?? '').toLowerCase();
    final contentType = _accepted[extension];
    if (contentType == null) {
      setState(() => _problem = 'Choose a JPEG, PNG or WEBP image.');
      return;
    }
    if (bytes.lengthInBytes > _maxBytes) {
      final mb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
      setState(() => _problem = 'That image is ${mb}MB. The limit is 5MB.');
      return;
    }

    setState(() {
      _problem = null;
      _removingBackground = true;
    });

    // Done here rather than on the server, which has nowhere near the memory
    // for it. A null answer means it could not be done — the photo goes up
    // with its background rather than the upload failing.
    final cutout = await removeBackground(bytes, contentType);
    if (!mounted) return;

    // The check above was on the photo as picked. A cut-out is a PNG, which
    // is lossless and can be far larger than the JPEG it came from, so the
    // result has to be measured again before it is sent. Without this an
    // 11-megapixel photo sailed past the check and was refused by the server.
    final tooBig = cutout != null && cutout.lengthInBytes > _maxBytes;
    final send = (cutout == null || tooBig) ? bytes : cutout;

    setState(() {
      _removingBackground = false;
      // Said out loud. Falling back silently is what made a photo that kept
      // its background indistinguishable from the feature not being built,
      // and left no way to tell which without reading the code.
      _note = cutout == null
          ? 'The background could not be removed, so the photo went up as it '
              'is. It usually means the tool could not be reached.'
          : tooBig
              ? 'The photo kept its background: without it the file came out '
                  'too large to store. A smaller photo will work.'
              : null;
    });

    final asCutout = identical(send, cutout);
    StoreProvider.of<AppState>(context).dispatch(
      UploadDoctorProfileImageAction(
        bytes: send,
        filename: asCutout ? '${_stem(file.name)}.png' : file.name,
        contentType: asCutout ? 'image/png' : contentType,
      ),
    );
  }

  static String _stem(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot <= 0 ? filename : filename.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProfileViewModel>(
      converter: _ProfileViewModel.fromStore,
      builder: (context, vm) {
        // A stored URL can say http:// even though the host only serves
        // HTTPS; the browser will not load that on an HTTPS page.
        final url = secureImageUrl(vm.doctor?.profileImage);
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(110),
              child: SizedBox(
                width: 190,
                height: 180,
                child: url == null || url.isEmpty
                    ? Image.asset('assets/doctors.png', fit: BoxFit.cover)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        // A photo that will not load should not leave a broken
                        // box where the doctor's face belongs.
                        errorBuilder: (context, _, __) =>
                            Image.asset('assets/doctors.png', fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsButton(
              _removingBackground
                  ? 'Removing background…'
                  : vm.isSaving
                      ? 'Uploading…'
                      : 'Upload photo',
              icon: Icons.photo_camera_outlined,
              onTap: _removingBackground || vm.isSaving ? null : _pick,
            ),
            if (_removingBackground) ...[
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'The first photo takes a while — the tool downloads itself '
                  'once, then it is quick.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A9E9E)),
                ),
              ),
            ],
            if (_problem != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _problem!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111)),
                ),
              ),
            ],
            if (_note != null && _problem == null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A7B22)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProfessionalDetails extends StatefulWidget {
  const _ProfessionalDetails();

  @override
  State<_ProfessionalDetails> createState() => _ProfessionalDetailsState();
}

class _ProfessionalDetailsState extends State<_ProfessionalDetails> {
  final _qualification = TextEditingController();
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

  /// Set when this screen sends a save, so the answer can be reported here.
  bool _awaitingSave = false;

  /// Catalogue ids of the schemes this doctor accepts.
  Set<int> _medicalAidIds = {};

  /// One consulting window per weekday, as the backend stores them. Days the
  /// doctor does not work hold null.
  final Map<String, _Window?> _hours = {
    for (final day in _weekdays) day: null,
  };

  /// Extra windows the doctor already had. The form edits one per day, so
  /// these are carried through untouched rather than silently dropped.
  final Map<String, List<String>> _extraWindows = {};

  static const _weekdays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

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
    _qualification.dispose();
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
    _qualification.text = doctor.qualification ?? '';
    _experience.text = doctor.experience?.toString() ?? '';
    _clinicName.text = doctor.clinicName ?? '';
    _clinicAddress.text = doctor.clinicAddress ?? '';
    _city.text = doctor.city ?? '';
    _zipCode.text = doctor.zipCode ?? '';
    _specialization = doctor.specialization;
    _province = _provinces.contains(doctor.province) ? doctor.province : null;
    _medicalAidIds = doctor.medicalAids.map((s) => s.id).toSet();
    _prefillHours(doctor.availability);
    _prefilled = true;
  }

  void _prefillHours(Map<String, List<String>>? availability) {
    if (availability == null) return;
    for (final day in _weekdays) {
      final windows = availability[day] ?? const [];
      _hours[day] = windows.isEmpty ? null : _Window.parse(windows.first);
      if (windows.length > 1) {
        _extraWindows[day] = windows.sublist(1);
      }
    }
  }

  /// Rebuilds the availability map the backend expects, keeping any extra
  /// windows this form does not edit.
  Map<String, List<String>> _availabilityPayload() {
    return {
      for (final day in _weekdays)
        day: [
          if (_hours[day] != null) _hours[day]!.asRange,
          ...?_extraWindows[day],
        ],
    };
  }

  /// Returns the first problem with the entered hours, or null.
  String? _hoursProblem() {
    for (final day in _weekdays) {
      final window = _hours[day];
      if (window == null) continue;
      if (!window.isValid) {
        return 'Consulting hours must look like 08:00, and the closing time '
            'must be later than the opening time.';
      }
    }
    return null;
  }
  void _save() {
    final experienceText = _experience.text.trim();
    final experience = experienceText.isEmpty ? null : int.tryParse(experienceText);
    if (experienceText.isNotEmpty && experience == null) {
      setState(() => _problem = 'Years of experience must be a number.');
      return;
    }
    final hoursProblem = _hoursProblem();
    if (hoursProblem != null) {
      setState(() => _problem = hoursProblem);
      return;
    }
    setState(() => _problem = null);
    _awaitingSave = true;

    StoreProvider.of<AppState>(context).dispatch(
      UpdateDoctorProfileAction(
        specialization: _specialization,
        qualification: _qualification.text.trim(),
        experience: experience,
        clinicName: _clinicName.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        city: _city.text.trim(),
        province: _province,
        zipCode: _zipCode.text.trim(),
        medicalAidIds: _medicalAidIds.toList(),
        availability: _availabilityPayload(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProfileViewModel>(
      converter: _ProfileViewModel.fromStore,
      onWillChange: _onChange,
      builder: (context, vm) {
        _prefill(vm.doctor);
        return _buildScreen(context, vm);
      },
    );
  }

  /// Reports how a save this screen sent turned out, once it has. Saving
  /// used to give no sign either way.
  void _onChange(_ProfileViewModel? previous, _ProfileViewModel vm) {
    if (!_awaitingSave || vm.isSaving) return;
    _awaitingSave = false;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your professional details are saved')),
      );
    }
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
                  // There was a "Medical License Number" here with nowhere to
                  // be stored; in South Africa the HPCSA number is the
                  // registration. Qualification has a column, and goes out
                  // with the doctor's name.
                  Expanded(
                    child: _Field(
                      label: 'Qualification',
                      hint: 'MBChB (UCT)',
                      controller: _qualification,
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
        isExpanded: true,
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
        isExpanded: true,
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
              const SizedBox(height: 28),
              const SettingsSectionTitle('Consulting Hours', muted: true),
              const SizedBox(height: 4),
              const Text(
                'The hours patients can book you for. Untick a day to show as '
                'closed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF748486)),
              ),
              const SizedBox(height: 10),
              for (final day in _weekdays)
                _DayHoursRow(
                  day: day,
                  window: _hours[day],
                  onChanged: (window) => setState(() => _hours[day] = window),
                ),
            ],
          ),
        ),
                const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SignatureArea(
            onSave: vm.isSaving ? null : _save,
            isSaving: vm.isSaving,
            errorMessage: _problem ?? (_awaitingSave ? null : vm.errorMessage),
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
///
/// Uses the same 14px check as the rest of settings, but driven by the
/// parent's selection — [SmallCheck] keeps its own state from its first
/// build, which would drift once the catalogue arrives after the profile.
class _MedicalAidPicker extends StatelessWidget {
  const _MedicalAidPicker({
    required this.catalogue,
    required this.selected,
    required this.onChanged,
  });

  final List<MedicalAidScheme> catalogue;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  void _toggle(int id) {
    final next = {...selected};
    if (!next.remove(id)) next.add(id);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (catalogue.isEmpty) {
      // Either the catalogue has not arrived yet or this backend does not
      // have it. Say so rather than showing an empty box that looks broken.
      return const Text(
        'Medical aid list unavailable.',
        style: TextStyle(fontSize: 11, color: Color(0xFF748486)),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 10,
      children: [
        for (final scheme in catalogue)
          SizedBox(
            width: 230,
            child: _SchemeCheck(
              label: scheme.name,
              checked: selected.contains(scheme.id),
              onTap: () => _toggle(scheme.id),
            ),
          ),
      ],
    );
  }
}

/// The settings check mark, without [SmallCheck]'s internal state.
class _SchemeCheck extends StatelessWidget {
  const _SchemeCheck({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.4),
              borderRadius: BorderRadius.circular(2),
            ),
            child: checked ? const Icon(Icons.check, size: 11) : null,
          ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// One consulting window, "08:00-17:00" as the backend stores it.
class _Window {
  const _Window(this.from, this.to);

  factory _Window.parse(String raw) {
    final parts = raw.split('-');
    return _Window(
      parts.isNotEmpty ? parts[0].trim() : '',
      parts.length > 1 ? parts[1].trim() : '',
    );
  }

  final String from;
  final String to;

  String get asRange => '$from-$to';

  static final _time = RegExp(r'^\d{2}:\d{2}$');

  /// The backend rejects anything that is not HH:MM-HH:MM, and refuses a
  /// closing time that is not after the opening one.
  bool get isValid =>
      _time.hasMatch(from) && _time.hasMatch(to) && to.compareTo(from) > 0;
}

/// One weekday's hours: a check to open or close the day, and the window.
class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.day,
    required this.window,
    required this.onChanged,
  });

  final String day;
  final _Window? window;
  final ValueChanged<_Window?> onChanged;

  String get _label => '${day[0].toUpperCase()}${day.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final open = window != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: _SchemeCheck(
              label: _label,
              checked: open,
              // Reopening a day lands on the usual working window rather than
              // two empty boxes the doctor has to fill in from scratch.
              onTap: () => onChanged(open ? null : const _Window('08:00', '17:00')),
            ),
          ),
          if (open) ...[
            SizedBox(
              width: 90,
              child: _TimeBox(
                value: window!.from,
                onChanged: (v) => onChanged(_Window(v, window!.to)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(fontSize: 11)),
            ),
            SizedBox(
              width: 90,
              child: _TimeBox(
                value: window!.to,
                onChanged: (v) => onChanged(_Window(window!.from, v)),
              ),
            ),
          ] else
            const Text('Closed',
                style: TextStyle(fontSize: 11, color: Color(0xFF748486))),
        ],
      ),
    );
  }
}

/// A plain HH:MM box, styled like the other settings inputs.
class _TimeBox extends StatefulWidget {
  const _TimeBox({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TimeBox> createState() => _TimeBoxState();
}

class _TimeBoxState extends State<_TimeBox> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_TimeBox old) {
    super.didUpdateWidget(old);
    // Only follow an external change, so typing is never interrupted.
    if (widget.value != _controller.text && widget.value != old.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        isDense: true,
        hintText: '08:00',
        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFC1C1C1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: const Color(0xFFEAF7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// The foot of Professional Details: how prescriptions are signed, where the
/// doctor's registration stands, and the Save button for the whole screen.
///
/// It used to offer "Draw your signature" (which did nothing), "Upload
/// Signature" (which picked a file and threw it away), a preview of a made-up
/// scribble, and a fixed "Not Verified" badge. Nothing stores a signature
/// image: the server signs each prescription digitally when the doctor
/// presses Sign, and the PDF carries that signature's fingerprint.
class _SignatureArea extends StatelessWidget {
  const _SignatureArea({this.onSave, this.errorMessage, this.isSaving = false});

  final VoidCallback? onSave;
  final String? errorMessage;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    const note = TextStyle(fontSize: 12, color: Color(0xFF748486), height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Signing Prescriptions', muted: true),
        const SizedBox(height: 8),
        const Text(
          'You sign each prescription digitally when you press Sign on it, '
          'while signed in. Nothing needs drawing or uploading: the PDF carries '
          'a fingerprint of that signature, which a pharmacy can check.',
          style: note,
        ),
        const SizedBox(height: 22),
        const SettingsSectionTitle('HPCSA Registration', muted: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Not checked yet',
            style: TextStyle(fontSize: 11, color: Color(0xFF8A6D00)),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pholders does not check HPCSA numbers against the register yet. '
          'To correct yours, contact support.',
          style: note,
        ),
        const SizedBox(height: 22),
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
          child: SettingsButton(isSaving ? 'Saving…' : 'Save Changes',
              icon: Icons.save_outlined, width: 160, height: 34, onTap: onSave),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.hint,
    this.inputFormatters,
    this.controller,
    this.readOnly = false,
  });

  final String label;
  final String? hint;
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
          inputFormatters: inputFormatters,
          controller: controller,
          readOnly: readOnly,
        ),
      ],
    );
  }
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

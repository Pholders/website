import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../data/pharmacy_profile.dart';

const Color _teal = Color(0xFF309CA3);
const Color _tealBorder = Color(0xFF6DD0D8);
const Color _textDark = Color(0xFF1F2937);
const Color _textMuted = Color(0xFF6B7280);
const Color _fieldBg = Color(0xFFE8F8F8);
const Color _errorRed = Color(0xFFDC2626);

/// One text box on a settings page, tied to a column of the pharmacy record.
class ProfileField {
  const ProfileField(
    this.column,
    this.label, {
    this.required = false,
    this.readOnly = false,
    this.hint,
    this.lines = 1,
  });

  final String column;
  final String label;
  final bool required;

  /// Shown but not sent: email and licence number change elsewhere.
  final bool readOnly;
  final String? hint;
  final int lines;
}

/// A titled group of fields.
class ProfileSection {
  const ProfileSection(this.title, this.fields);
  final String? title;
  final List<ProfileField> fields;
}

/// The settings sidebar's routes, shared by every pharmacy settings page.
void openPharmacySetting(BuildContext context, String id) {
  final route = switch (id) {
    'personal_information' => AppRoutes.pharmacySettingsPersonalInfo,
    'pharmacy_details' => AppRoutes.pharmacySettingsPharmacyDetails,
    'professional' => AppRoutes.pharmacySettingsProfessional,
    'profile' => AppRoutes.pharmacySettingsProfile,
    'notification_settings' ||
    'preferences_notifications' =>
      AppRoutes.pharmacySettingsNotifications,
    'notification_center' => AppRoutes.pharmacySettingsNotificationCenter,
    'linked_services' => AppRoutes.pharmacySettingsLinkedServices,
    _ => null,
  };
  if (route != null) context.go(route);
}

/// A pharmacy settings page whose fields load from, and save to, the
/// pharmacy's record on the server.
class PharmacyProfileForm extends StatefulWidget {
  const PharmacyProfileForm({
    super.key,
    required this.title,
    required this.selectedItemId,
    this.sections = const [],
    this.includeHours = false,
    this.includeServices = false,
    this.repository,
  });

  final String title;
  final String selectedItemId;
  final List<ProfileSection> sections;

  /// Weekday, Saturday and Sunday opening hours, and open around the clock.
  final bool includeHours;

  /// Delivery, delivery radius, website and description.
  final bool includeServices;

  /// Injected by tests; the app uses the registered one.
  final PharmacyProfileRepository? repository;

  @override
  State<PharmacyProfileForm> createState() => _PharmacyProfileFormState();
}

class _PharmacyProfileFormState extends State<PharmacyProfileForm> {
  late final PharmacyProfileRepository _repo =
      widget.repository ?? sl<PharmacyProfileRepository>();
  final _form = GlobalKey<FormState>();

  final _controllers = <String, TextEditingController>{};
  final _weekdayHours = TextEditingController();
  final _saturdayHours = TextEditingController();
  final _sundayHours = TextEditingController();
  final _radius = TextEditingController();
  bool _open24 = false;
  bool _delivers = false;

  PharmacyProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  Iterable<ProfileField> get _fields =>
      widget.sections.expand((section) => section.fields);

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      _controllers[field.column] = TextEditingController();
    }
    if (widget.includeServices) {
      _controllers['website'] = TextEditingController();
      _controllers['description'] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      ..._controllers.values,
      _weekdayHours,
      _saturdayHours,
      _sundayHours,
      _radius,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _repo.fetch();
      if (!mounted) return;
      _fill(profile);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = _messageFor(error, 'Your details could not be loaded.');
      });
    }
  }

  void _fill(PharmacyProfile profile) {
    _profile = profile;
    for (final entry in _controllers.entries) {
      entry.value.text = profile.text(entry.key);
    }
    final hours = profile.operatingHours;
    _weekdayHours.text = hoursToText(hours['monday']);
    _saturdayHours.text = hoursToText(hours['saturday']);
    _sundayHours.text = hoursToText(hours['sunday']);
    _open24 = profile.flag('is_24_hours');
    _delivers = profile.flag('delivery_available');
    final radius = double.tryParse(profile.text('delivery_radius'));
    _radius.text = radius == null
        ? ''
        : (radius == radius.roundToDouble()
            ? radius.toStringAsFixed(0)
            : radius.toString());
  }

  Map<String, dynamic> _changes() {
    String? blankToNull(String text) =>
        text.trim().isEmpty ? null : text.trim();

    final changes = <String, dynamic>{};
    for (final field in _fields) {
      if (field.readOnly) continue;
      final text = _controllers[field.column]!.text;
      changes[field.column] = field.required ? text.trim() : blankToNull(text);
    }
    if (widget.includeHours) {
      final weekday = hoursFromText(_weekdayHours.text)!;
      changes['is_24_hours'] = _open24;
      changes['operating_hours'] = {
        for (final day in weekdays) day: weekday,
        'saturday': hoursFromText(_saturdayHours.text)!,
        'sunday': hoursFromText(_sundayHours.text)!,
      };
    }
    if (widget.includeServices) {
      changes['delivery_available'] = _delivers;
      changes['delivery_radius'] =
          _delivers ? double.tryParse(_radius.text.trim()) : null;
      changes['website'] = blankToNull(_controllers['website']!.text);
      changes['description'] = blankToNull(_controllers['description']!.text);
    }
    return changes;
  }

  Future<void> _save() async {
    if (_saving || _profile == null) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final saved = await _repo.save(_changes());
      if (!mounted) return;
      setState(() {
        _fill(saved);
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved'),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_messageFor(error, 'Your changes were not saved.')),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fieldBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(
            selectedItemId: widget.selectedItemId,
            onMenuItemSelected: (id) => openPharmacySetting(context, id),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _card(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() {
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
                  padding: const EdgeInsets.all(28),
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final header = Row(children: [
      Expanded(
        child: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ),
      if (_profile != null) _saveButton(compact: true),
    ]);

    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _teal)),
          ),
        ],
      );
    }
    final loadError = _loadError;
    if (loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 32),
          Text(loadError, style: const TextStyle(color: _textMuted)),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 24),
          for (final section in widget.sections) ...[
            if (section.title != null) _sectionTitle(section.title!),
            for (final field in section.fields) _textField(field),
            const SizedBox(height: 12),
          ],
          if (widget.includeHours) ..._hours(),
          if (widget.includeServices) ..._services(),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: _saveButton()),
        ],
      ),
    );
  }

  List<Widget> _hours() {
    String? check(String? text) => hoursFromText(text ?? '') == null
        ? 'Use 24-hour times like 08:00-18:00, or Closed'
        : null;
    return [
      _sectionTitle('Operating Hours'),
      _switchRow(
        'Open 24 hours',
        _open24,
        (v) => setState(() => _open24 = v),
        key: 'open24',
      ),
      _row('Monday to Friday', _input(_weekdayHours, 'hours-weekday',
          hint: '08:00-18:00', validator: check)),
      _row('Saturday', _input(_saturdayHours, 'hours-saturday',
          hint: '09:00-13:00 or Closed', validator: check)),
      _row('Sunday', _input(_sundayHours, 'hours-sunday',
          hint: 'Closed', validator: check)),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _services() {
    return [
      _sectionTitle('Services'),
      _switchRow(
        'Delivers to patients',
        _delivers,
        (v) => setState(() => _delivers = v),
        key: 'delivers',
      ),
      if (_delivers)
        _row(
          'Delivery radius (km)',
          _input(_radius, 'radius', hint: '5', validator: (text) {
            final value = double.tryParse((text ?? '').trim());
            return value == null || value <= 0 ? 'Enter a distance in km' : null;
          }),
        ),
      _row('Website', _input(_controllers['website']!, 'website')),
      _row(
        'About the pharmacy',
        _input(_controllers['description']!, 'description', lines: 3),
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
      );

  Widget _textField(ProfileField field) {
    return _row(
      field.required ? '${field.label} *' : field.label,
      _input(
        _controllers[field.column]!,
        field.column,
        hint: field.hint,
        lines: field.lines,
        readOnly: field.readOnly,
        validator: field.required
            ? (text) => (text ?? '').trim().isEmpty
                ? '${field.label} is needed'
                : null
            : null,
      ),
    );
  }

  Widget _row(String label, Widget input) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ),
            Expanded(child: input),
          ],
        ),
      );

  Widget _input(
    TextEditingController controller,
    String key, {
    String? hint,
    int lines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: ValueKey('pharmacy-field-$key'),
      controller: controller,
      readOnly: readOnly,
      maxLines: lines,
      validator: validator,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? _textMuted : _textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        helperText: readOnly ? 'Contact support to change this' : null,
        filled: true,
        fillColor: _fieldBg,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _switchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    required String key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
        ),
        Switch(
          key: ValueKey('pharmacy-switch-$key'),
          value: value,
          activeThumbColor: _teal,
          onChanged: onChanged,
        ),
      ]),
    );
  }

  Widget _saveButton({bool compact = false}) {
    final label = _saving ? 'Saving…' : (compact ? 'Save' : 'Save Changes');
    return Material(
      color: compact ? _tealBorder : _teal,
      shape: const StadiumBorder(),
      child: InkWell(
        key: ValueKey(compact ? 'pharmacy-save-top' : 'pharmacy-save'),
        customBorder: const StadiumBorder(),
        onTap: _saving ? null : _save,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 24,
            vertical: compact ? 8 : 10,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

String _messageFor(Object error, String fallback) {
  if (error is ApiException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}

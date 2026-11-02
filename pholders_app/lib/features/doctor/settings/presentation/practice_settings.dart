import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import '../../../auth/data/models/doctor.dart';
import 'settings_frame.dart';

/// Fees Setup (tab 0) and Notification Settings (tab 1).
///
/// Fees Setup used to list video, phone, time-based, follow-up, after-hours,
/// cancellation and late fees, an "Accept Medical Aid" switch and a list of
/// schemes with Discovery ticked. Only the consultation fee was ever stored.
/// Notification Settings was fifteen switches and boxes with nothing behind
/// them. Both now show only what the server keeps.
class PracticeSettings extends StatelessWidget {
  const PracticeSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return initialTab == 1 ? const _NotificationSettings() : const _FeesSetup();
  }
}

class _FeesViewModel {
  const _FeesViewModel({required this.isSaving, this.doctor, this.errorMessage});

  factory _FeesViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _FeesViewModel(
      isSaving: auth.isLoading,
      doctor: auth.doctor,
      errorMessage: auth.errorMessage,
    );
  }

  final bool isSaving;
  final Doctor? doctor;
  final String? errorMessage;

  /// The record stores an ISO code; the screen shows a symbol.
  String get currencySymbol => switch (doctor?.currency) {
        'USD' => r'$',
        'GBP' => '£',
        'EUR' => '€',
        _ => 'R',
      };
}

// ─── Fees Setup ───────────────────────────────────────────────────────────────

/// The consultation fee: the one fee the doctor record has. Booking copies it
/// onto the appointment, and a doctor with none set cannot be booked.
class _FeesSetup extends StatefulWidget {
  const _FeesSetup();

  @override
  State<_FeesSetup> createState() => _FeesSetupState();
}

class _FeesSetupState extends State<_FeesSetup> {
  final _fee = TextEditingController();
  bool _prefilled = false;
  bool _awaitingSave = false;
  String? _problem;

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  void _save() {
    final fee = double.tryParse(_fee.text.trim().replaceAll(',', '.'));
    if (fee == null || fee <= 0) {
      setState(() => _problem = 'Enter your fee, for example 450.00');
      return;
    }
    if (fee > 100000) {
      setState(() => _problem = 'That fee looks too large. Check the amount.');
      return;
    }
    setState(() => _problem = null);
    _awaitingSave = true;
    StoreProvider.of<AppState>(context)
        .dispatch(UpdateDoctorProfileAction(consultationFee: fee));
  }

  void _onChange(_FeesViewModel? previous, _FeesViewModel vm) {
    if (!_awaitingSave || vm.isSaving) return;
    _awaitingSave = false;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your consultation fee is saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _FeesViewModel>(
      converter: _FeesViewModel.fromStore,
      onWillChange: _onChange,
      builder: (context, vm) {
        final fee = vm.doctor?.consultationFee;
        if (!_prefilled && vm.doctor != null) {
          _fee.text = fee == null ? '' : fee.toStringAsFixed(2);
          _prefilled = true;
        }
        final error = _problem ?? (_awaitingSave ? null : vm.errorMessage);
        return DoctorSettingsFrame(
          selectedItemId: 'fees_setup',
          title: 'Fees Setup',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsSectionTitle('Consultation Fee'),
                  const SizedBox(height: 6),
                  const Text(
                    'What a patient pays for one consultation with you. It is '
                    'copied onto each booking when it is made, and patients '
                    'cannot book you until it is set.',
                    style: settingsNote,
                  ),
                  const SizedBox(height: 14),
                  if (vm.doctor != null && fee == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Not set yet, so patients cannot book you.',
                        style: TextStyle(fontSize: 13, color: Color(0xFFCC1111)),
                      ),
                    ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      key: const ValueKey('fee'),
                      controller: _fee,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '${vm.currencySymbol} ',
                        hintText: '450.00',
                        isDense: true,
                        filled: true,
                        fillColor: SettingsShell.panelMint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFFCFECEE)),
                        ),
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(error,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111))),
                    ),
                  SettingsButton(
                    vm.isSaving ? 'Saving…' : 'Save Fee',
                    icon: Icons.save_outlined,
                    width: 140,
                    height: 34,
                    onTap: vm.isSaving ? null : _save,
                  ),
                  const SizedBox(height: 26),
                  const SettingsDivider(),
                  const SizedBox(height: 14),
                  const SettingsSectionTitle('Medical Aid'),
                  const SizedBox(height: 6),
                  const Text(
                    'The schemes you accept are chosen on Professional Details, '
                    'where patients searching by their plan find you.',
                    style: settingsNote,
                  ),
                  const SizedBox(height: 10),
                  SettingsButton(
                    'Open Professional Details',
                    width: 230,
                    height: 32,
                    filled: false,
                    onTap: () => context.go(AppRoutes.doctorSettingsProfessional),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Notification Settings ────────────────────────────────────────────────────

/// The kinds of notification a doctor can switch off, with the backend's key.
const notificationKinds = <(String, String, String)>[
  ('newBookings', 'New bookings',
      'A patient has paid for a booking and it waits for you to accept it.'),
  ('appointmentChanges', 'Moved or cancelled appointments',
      'A patient moves an appointment to another time, or cancels it.'),
  ('prescriptionsDispensed', 'Dispensed prescriptions',
      'A pharmacy dispenses a script you wrote.'),
  ('reviews', 'Reviews', 'A patient rates you, or changes their rating.'),
];

/// Which notifications the doctor wants in their Notification Centre. Saved
/// on the doctor record and checked before each one is written.
class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings();

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  Map<String, bool>? _choices;
  bool _awaitingSave = false;

  bool _isOn(String key, Doctor? doctor) =>
      _choices?[key] ?? doctor?.wantsNotification(key) ?? true;

  void _save(Doctor? doctor) {
    _awaitingSave = true;
    StoreProvider.of<AppState>(context).dispatch(UpdateDoctorProfileAction(
      notificationPreferences: {
        for (final (key, _, _) in notificationKinds) key: _isOn(key, doctor),
      },
    ));
  }

  void _onChange(_FeesViewModel? previous, _FeesViewModel vm) {
    if (!_awaitingSave || vm.isSaving) return;
    _awaitingSave = false;
    if (vm.errorMessage == null) {
      setState(() => _choices = null); // the saved profile is the truth now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your notification settings are saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _FeesViewModel>(
      converter: _FeesViewModel.fromStore,
      onWillChange: _onChange,
      builder: (context, vm) {
        final error = _awaitingSave ? null : vm.errorMessage;
        return DoctorSettingsFrame(
          selectedItemId: 'notification_settings',
          title: 'Notification Settings',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose what appears in your Notification Centre and on the '
                    'bell. Notifications show in the portal only; nothing is '
                    'emailed or texted.',
                    style: settingsNote,
                  ),
                  const SizedBox(height: 16),
                  for (final (key, label, detail) in notificationKinds)
                    _ChoiceRow(
                      key: ValueKey('pref-$key'),
                      label: label,
                      detail: detail,
                      value: _isOn(key, vm.doctor),
                      onChanged: vm.isSaving
                          ? null
                          : (on) => setState(() =>
                              _choices = {...?_choices, key: on}),
                    ),
                  const SizedBox(height: 18),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(error,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111))),
                    ),
                  Row(
                    children: [
                      SettingsButton(
                        vm.isSaving ? 'Saving…' : 'Save Changes',
                        icon: Icons.save_outlined,
                        width: 160,
                        height: 34,
                        onTap: vm.isSaving || _choices == null
                            ? null
                            : () => _save(vm.doctor),
                      ),
                      const SizedBox(width: 12),
                      SettingsButton(
                        'Open Notification Centre',
                        width: 220,
                        height: 34,
                        filled: false,
                        onTap: () => context.go(AppRoutes.doctorNotifications),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(detail, style: settingsNote),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2EC4C4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

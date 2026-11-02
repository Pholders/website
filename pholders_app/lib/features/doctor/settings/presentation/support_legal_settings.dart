import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import '../../../auth/data/doctor_auth_repository.dart';
import '../../../auth/data/models/doctor.dart';
import 'settings_frame.dart';

/// Help Center (0), Privacy Policy (1), Terms of Service (2), Contact
/// Support (3).
///
/// Help Center had a search box that searched nothing and rows that went
/// nowhere. The policy pages were two invented sentences each, one promising
/// data "protected by your security preferences". Contact Support sent
/// nothing. The legal pages also always highlighted Privacy Policy.
class SupportLegalSettings extends StatelessWidget {
  const SupportLegalSettings({super.key, this.initialTab = 0, this.repository});

  final int initialTab;
  final DoctorAuthRepository? repository;

  @override
  Widget build(BuildContext context) {
    return switch (initialTab) {
      1 => const _LegalPanel(
          selectedItemId: 'privacy_policy',
          title: 'Privacy Policy',
          facts: _privacyFacts,
        ),
      2 => const _LegalPanel(
          selectedItemId: 'terms_of_service',
          title: 'Terms of Service',
          facts: _termsFacts,
        ),
      3 => _ContactSupport(repository ?? sl<DoctorAuthRepository>()),
      _ => const _HelpCenter(),
    };
  }
}

// ─── Help Center ──────────────────────────────────────────────────────────────

class _HelpCenter extends StatelessWidget {
  const _HelpCenter();

  static const _topics = <(IconData, String, String, String)>[
    (Icons.person_outline, 'Your profile', 'Your photo, the About text patients read, name and phone.', AppRoutes.doctorSettingsProfile),
    (Icons.badge_outlined, 'Professional details', 'Qualification, practice address, the medical aids you accept, and your consulting hours.', AppRoutes.doctorSettingsProfessional),
    (Icons.payments_outlined, 'Your consultation fee', 'Patients cannot book you until it is set.', '${AppRoutes.doctorSettingsPractice}?tab=0'),
    (Icons.notifications_none, 'Notification settings', 'Choose which notifications you get.', '${AppRoutes.doctorSettingsPractice}?tab=1'),
    (Icons.lock_outline, 'Password and devices', 'Change your password and sign out devices you no longer use.', AppRoutes.doctorSettingsSecurity),
    (Icons.support_agent, 'Still stuck?', 'Send a message to the Pholders team.', '${AppRoutes.doctorSettingsSupportLegal}?tab=3'),
  ];

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: 'help_center',
      title: 'Help Center',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('Where to find each setting.', style: settingsNote),
        ),
        for (final (icon, title, text, route) in _topics)
          InkWell(
            onTap: () => context.go(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleIconButton(icon: icon, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(text, style: const TextStyle(fontSize: 12, color: SettingsShell.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E8E)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Privacy Policy and Terms ─────────────────────────────────────────────────

/// Only statements about what the platform actually does. The full documents
/// need legal advice and are not written here.
const _privacyFacts = <(String, String)>[
  ('Who sees a patient\'s record',
      'A patient\'s health record (vitals, history, documents and medications) is shared with the doctors that patient books. Booking is the patient\'s consent, as the SRS sets out. Pharmacies do not see vitals.'),
  ('Your sign-ins',
      'Each sign-in is recorded with its device and address, which you can see under Device Management and Login Activity, and end from there.'),
  ('Payments',
      'Card payments are handled by Stripe. Pholders does not store card numbers.'),
];

const _termsFacts = <(String, String)>[
  ('Prescriptions',
      'You sign each prescription digitally while signed in. A signed prescription can be revoked, but not edited.'),
  ('Your details',
      'Keep your profile, fee and consulting hours accurate: patients book and pay against them.'),
  ('Registration',
      'Your HPCSA number is recorded at signup but not yet checked against the register.'),
];

class _LegalPanel extends StatelessWidget {
  const _LegalPanel({
    required this.selectedItemId,
    required this.title,
    required this.facts,
  });

  final String selectedItemId;
  final String title;
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: selectedItemId,
      title: title,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'The full $title is being prepared with legal advice and will '
            'appear here. Until then, these are facts about how Pholders '
            'works today.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B5300)),
          ),
        ),
        for (final (heading, body) in facts) ...[
          SettingsSectionTitle(heading),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFF4B4B4B), height: 1.5)),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

// ─── Contact Support ──────────────────────────────────────────────────────────

class _ContactSupport extends StatefulWidget {
  const _ContactSupport(this.repo);

  final DoctorAuthRepository repo;

  @override
  State<_ContactSupport> createState() => _ContactSupportState();
}

class _ContactSupportState extends State<_ContactSupport> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _problem;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(Doctor? doctor) async {
    if (doctor == null) {
      setState(() => _problem = 'Your profile has not loaded yet. Try again in a moment.');
      return;
    }
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(() => _problem = 'Add a subject and a message.');
      return;
    }
    setState(() {
      _problem = null;
      _sending = true;
    });
    try {
      await widget.repo.contactSupport(
        email: doctor.email,
        firstName: doctor.firstName,
        lastName: doctor.lastName,
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sent. The Pholders team will reply to ${doctor.email}.'),
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _problem = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _box(String label) => InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: SettingsShell.panelMint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFCFECEE)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Doctor?>(
      converter: (store) => store.state.authState.doctor,
      builder: (context, doctor) => DoctorSettingsFrame(
        selectedItemId: 'contact_support',
        title: 'Contact Support',
        children: [
          Text(
            doctor == null
                ? 'Write to the Pholders team.'
                : 'Sent from ${doctor.fullName} (${doctor.email}); the reply comes to that address.',
            style: settingsNote,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('subject'),
            controller: _subject,
            maxLength: 150,
            decoration: _box('Subject'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('message'),
            controller: _message,
            minLines: 5,
            maxLines: 10,
            maxLength: 3000,
            decoration: _box('Message'),
          ),
          if (_problem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_problem!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111))),
            ),
          SettingsButton(
            _sending ? 'Sending…' : 'Send Message',
            icon: Icons.send_outlined,
            width: 170,
            height: 34,
            onTap: _sending ? null : () => _send(doctor),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import '../../../auth/data/doctor_auth_repository.dart';
import '../../../auth/data/models/doctor_activity.dart';
import 'settings_frame.dart';

/// Security Settings (tab 0) and Device Management (tab 1).
///
/// Security Settings was switches for change password, biometrics,
/// two-factor, an auto-logout timer and alerts, and a "Log out of all
/// devices" button, none connected to anything. It now changes the password
/// and signs out other devices for real. Device Management listed real
/// sessions but its Log Out buttons did nothing; they now sign that device
/// out. A third, unreachable Login Activity screen of invented April
/// sign-ins is gone; the real one is LoginActivityPage.
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key, this.initialTab = 0, this.repository});

  final int initialTab;
  final DoctorAuthRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<DoctorAuthRepository>();
    return initialTab == 1
        ? _DeviceManagement(repo)
        : _SecuritySettings(repo);
  }
}

String _messageOf(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Try again.';

void _tell(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String _devicesSignedOut(int n) => n == 0
    ? 'No other devices were signed in.'
    : '$n other device${n == 1 ? ' was' : 's were'} signed out.';

// ─── Security Settings ────────────────────────────────────────────────────────

class _SecuritySettings extends StatefulWidget {
  const _SecuritySettings(this.repo);

  final DoctorAuthRepository repo;

  @override
  State<_SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<_SecuritySettings> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _changing = false;
  bool _signingOut = false;
  String? _problem;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// The same rules the server applies, checked here so a mistake is
  /// answered at once. The server still has the final say.
  static String? passwordProblem(String password) {
    if (password.length < 8) return 'Use at least 8 characters.';
    if (!RegExp('[A-Z]').hasMatch(password)) return 'Include a capital letter.';
    if (!RegExp('[a-z]').hasMatch(password)) return 'Include a small letter.';
    if (!RegExp('[0-9]').hasMatch(password)) return 'Include a number.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Include a symbol, such as ! or #.';
    }
    return null;
  }

  Future<void> _changePassword() async {
    final current = _current.text;
    final next = _new.text;
    String? problem;
    if (current.isEmpty) {
      problem = 'Enter your current password.';
    } else if (next != _confirm.text) {
      problem = 'The new password and its confirmation are different.';
    } else if (next == current) {
      problem = 'The new password must be different from the current one.';
    } else {
      problem = passwordProblem(next);
    }
    setState(() => _problem = problem);
    if (problem != null) return;

    setState(() => _changing = true);
    try {
      final signedOut = await widget.repo
          .changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      _current.clear();
      _new.clear();
      _confirm.clear();
      _tell(context, 'Password changed. ${_devicesSignedOut(signedOut)}');
    } catch (e) {
      if (mounted) setState(() => _problem = _messageOf(e));
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _signOutOthers() async {
    setState(() => _signingOut = true);
    try {
      final n = await widget.repo.revokeOtherSessions();
      if (mounted) _tell(context, _devicesSignedOut(n));
    } catch (e) {
      if (mounted) _tell(context, _messageOf(e));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Widget _passwordField(String label, TextEditingController controller, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        obscureText: !_show,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: SettingsShell.panelMint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFCFECEE)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: 'security_settings',
      title: 'Security Settings',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionTitle('Change Password'),
              const SizedBox(height: 6),
              const Text(
                'At least 8 characters, with a capital and a small letter, a '
                'number and a symbol. Changing it signs out your other devices.',
                style: settingsNote,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _passwordField('Current password', _current, 'current'),
                    _passwordField('New password', _new, 'new'),
                    _passwordField('Confirm new password', _confirm, 'confirm'),
                    Row(
                      children: [
                        Checkbox(
                          value: _show,
                          onChanged: (v) => setState(() => _show = v ?? false),
                        ),
                        const Text('Show passwords', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_problem!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFCC1111))),
                ),
              SettingsButton(
                _changing ? 'Changing…' : 'Change Password',
                icon: Icons.lock_outline,
                width: 190,
                height: 34,
                onTap: _changing ? null : _changePassword,
              ),
              const SizedBox(height: 26),
              const SettingsDivider(),
              const SizedBox(height: 14),
              const SettingsSectionTitle('Signed-in Devices'),
              const SizedBox(height: 6),
              const Text(
                'If you signed in somewhere you no longer use, or think someone '
                'else has your password, sign out everywhere but here.',
                style: settingsNote,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SettingsButton(
                    _signingOut ? 'Signing out…' : 'Sign out all other devices',
                    icon: Icons.logout,
                    width: 250,
                    height: 34,
                    onTap: _signingOut ? null : _signOutOthers,
                  ),
                  SettingsButton(
                    'Device Management',
                    width: 190,
                    height: 34,
                    filled: false,
                    onTap: () => context.go(AppRoutes.doctorSettingsDevices),
                  ),
                  SettingsButton(
                    'Login Activity',
                    width: 160,
                    height: 34,
                    filled: false,
                    onTap: () => context.go(AppRoutes.doctorSettingsLoginActivity),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Device Management ────────────────────────────────────────────────────────

class _DeviceManagement extends StatefulWidget {
  const _DeviceManagement(this.repo);

  final DoctorAuthRepository repo;

  @override
  State<_DeviceManagement> createState() => _DeviceManagementState();
}

class _DeviceManagementState extends State<_DeviceManagement> {
  late Future<List<ActiveSession>> _sessions = widget.repo.fetchSessions();
  final Set<String> _busy = {};

  void _reload() {
    final next = widget.repo.fetchSessions();
    setState(() {
      _sessions = next;
    });
  }

  Future<void> _signOut(ActiveSession session) async {
    setState(() => _busy.add(session.id));
    try {
      await widget.repo.revokeSession(session.id);
      if (mounted) _tell(context, '${session.device} was signed out.');
    } catch (e) {
      if (mounted) _tell(context, _messageOf(e));
    } finally {
      if (mounted) {
        _busy.remove(session.id);
        _reload();
      }
    }
  }

  Future<void> _signOutOthers() async {
    setState(() => _busy.add('*'));
    try {
      final n = await widget.repo.revokeOtherSessions();
      if (mounted) _tell(context, _devicesSignedOut(n));
    } catch (e) {
      if (mounted) _tell(context, _messageOf(e));
    } finally {
      if (mounted) {
        _busy.remove('*');
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsFrame(
      selectedItemId: 'device_management',
      title: 'Device Management',
      children: [
        FutureBuilder<List<ActiveSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_messageOf(snapshot.error!),
                        style: const TextStyle(color: Colors.redAccent)),
                    TextButton(onPressed: _reload, child: const Text('Try again')),
                  ],
                ),
              );
            }

            final sessions = snapshot.data ?? const <ActiveSession>[];
            if (sessions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No active sessions.'),
              );
            }

            // The server lists them most recently active first, and this
            // page's own request has just made this device the most recent.
            final current = sessions.first;
            final others = sessions.skip(1).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsSectionTitle('This Device'),
                const SizedBox(height: 12),
                _DeviceRow(session: current, trailing: const Text('Active now')),
                const SizedBox(height: 22),
                const SettingsDivider(),
                const SizedBox(height: 12),
                SettingsSectionTitle('Other Devices (${others.length})'),
                const SizedBox(height: 10),
                if (others.isEmpty)
                  const Text('No other devices are signed in.')
                else
                  for (final session in others) ...[
                    _DeviceRow(
                      session: session,
                      trailing: SettingsButton(
                        _busy.contains(session.id) ? 'Signing out…' : 'Log Out',
                        width: 130,
                        height: 30,
                        filled: false,
                        onTap: _busy.isEmpty ? () => _signOut(session) : null,
                      ),
                    ),
                    const SettingsDivider(),
                  ],
                const SizedBox(height: 16),
                if (others.isNotEmpty)
                  SettingsButton(
                    _busy.contains('*') ? 'Signing out…' : 'Sign out all other devices',
                    icon: Icons.logout,
                    width: 250,
                    height: 34,
                    onTap: _busy.isEmpty ? _signOutOthers : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.session, required this.trailing});

  final ActiveSession session;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final seen = session.lastActivityAt?.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final when = seen == null
        ? ''
        : ' · last active ${seen.day}/${seen.month} ${two(seen.hour)}:${two(seen.minute)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.devices_outlined, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.device, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                Text('${session.ipAddress ?? 'Unknown address'}$when',
                    style: settingsNote),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

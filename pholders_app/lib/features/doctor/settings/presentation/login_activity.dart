import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/doctor_auth_repository.dart';
import '../../../auth/data/models/doctor_activity.dart';
import 'settings_frame.dart';

class LoginActivityPage extends StatefulWidget {
  const LoginActivityPage({super.key});

  @override
  State<LoginActivityPage> createState() => _LoginActivityPageState();
}

class _LoginActivityPageState extends State<LoginActivityPage> {
  // Read-only screen, so it reads the repository directly rather than adding
  // a store slice nothing else would use.
  late Future<List<DoctorActivity>> _activity;

  @override
  void initState() {
    super.initState();
    _activity = sl<DoctorAuthRepository>().fetchActivityLog();
  }

  @override
  Widget build(BuildContext context) {
    return DoctorSettingsLayout(
      selectedItemId: 'login_activity',
      child: doctorSettingsCard(
        context,
        title: 'Login Activity',
        children: [
          FutureBuilder<List<DoctorActivity>>(
            future: _activity,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                final e = snapshot.error;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    e is ApiException
                        ? e.message
                        : 'Could not load your account activity.',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              final entries = snapshot.data ?? const <DoctorActivity>[];
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No account activity recorded yet.'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const Divider(),
                    _activityEntry(
                      entries[i].formattedTime,
                      entries[i].ipAddress ?? 'Unknown location',
                      entries[i].label,
                      entries[i].succeeded ? 'Successful' : 'Failed',
                      entries[i].succeeded ? Icons.check_circle : Icons.error,
                      entries[i].succeeded ? Colors.teal : Colors.red,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // A "Suspicious Activity! This login was from a new location"
          // card sat here for every doctor, whatever their sign-ins, with
          // two buttons marked not in this phase. Nothing checks for
          // suspicious sign-ins, so it is gone. Signing out a device you do
          // not recognise is on Device Management.
          Text(
            'Do not recognise a sign-in? Sign that device out on Device '
            'Management, and change your password on Security Settings.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // The menu's links are in navigateDoctorSettings. This page had its own
  // copy, which matched 'profile' where the menu sends
  // 'personal_information', so Profile did nothing from here.

  Widget _activityEntry(String date, String location, String device, String status, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(date),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location),
          Text(device),
        ],
      ),
      trailing: Text(status, style: TextStyle(color: iconColor)),
    );
  }
}

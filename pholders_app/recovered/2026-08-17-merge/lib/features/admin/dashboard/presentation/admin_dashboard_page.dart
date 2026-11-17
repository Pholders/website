import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../store/app_state.dart';
import '../../../../core/auth/logout.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/utils/greeting.dart';
import '../../domain/entities/admin_profile.dart';
import '../../domain/repositories/admin_repository.dart';

/// Admin landing page.
///
/// Everything shown here is backed by a real response: the greeting name comes
/// from the store (written when the OTP was verified), the card from
/// `GET /users/admin/profile`. No placeholder tiles — the backend exposes no
/// admin endpoints for listing doctors, patients or orders, so inventing them
/// here would only look like working features.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<AdminProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = sl<AdminRepository>().getProfile();
  }

  void _reload() {
    setState(() => _profile = sl<AdminRepository>().getProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting reads the store, matching the doctor and pharmacy
                  // dashboards.
                  StoreConnector<AppState, String?>(
                    converter: (store) => store.state.authState.userName,
                    builder: (context, userName) {
                      final name = userName?.trim() ?? '';
                      return Text(
                        name.isEmpty
                            ? timeOfDayGreeting()
                            : '${timeOfDayGreeting()}, $name',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF102025),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PHolders administration',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                  const SizedBox(height: 28),
                  FutureBuilder<AdminProfile>(
                    future: _profile,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return _ProfileError(
                          message: snapshot.error.toString(),
                          onRetry: _reload,
                        );
                      }
                      return _ProfileCard(profile: snapshot.data!);
                    },
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () => performLogout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF309CA3),
                      side: const BorderSide(color: Color(0xFF309CA3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final AdminProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EDEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF309CA3).withValues(alpha: 0.12),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF309CA3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF102025),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _Field(label: 'Phone', value: profile.phone),
          _Field(label: 'Account status', value: profile.status),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final shown = (value == null || value!.trim().isEmpty) ? '—' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              shown,
              style: const TextStyle(fontSize: 13, color: Color(0xFF102025)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The API's own wording, surfaced through ServerFailure.toString().
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

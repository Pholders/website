// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../core/routing/app_routes.dart';

class PracticeSettingsPage extends StatelessWidget {
  const PracticeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'practice_settings',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: SettingsContentCard(
                title: 'Practice Settings',
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(28, 4, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionTitle('Practice Information'),
                        SizedBox(height: 10),
                        _Field(label: 'Practice Name'),
                        SizedBox(height: 24),
                        _Field(label: 'Practice Address'),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'City',
                                hint: 'Johannesburg',
                                trailing: Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF748486)),
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Province',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFFEAF8F8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    hint: Text('Gauteng'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Eastern Cape',
                                        child: Text('Eastern Cape'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Free State',
                                        child: Text('Free State'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Gauteng',
                                        child: Text('Gauteng'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'KwaZulu-Natal',
                                        child: Text('KwaZulu-Natal'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Limpopo',
                                        child: Text('Limpopo'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Mpumalanga',
                                        child: Text('Mpumalanga'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Northern Cape',
                                        child: Text('Northern Cape'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'North West',
                                        child: Text('North West'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Western Cape',
                                        child: Text('Western Cape'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 22),
                        SizedBox(
                          width: 210,
                          child: _Field(label: 'Postal Code', hint: '2001')),
                      ],
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

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go('${AppRoutes.doctorSettings}account?tab=0');
        break;
      case 'professional':
        context.go('${AppRoutes.doctorSettings}account?tab=1');
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPracticePage);
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.hint,
    this.icon,
    this.trailing,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        SizedBox(height: 5),
        SettingsInput(hint: hint, icon: icon, trailing: trailing, inputFormatters: inputFormatters),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

/// Pharmacy notification settings stub.
///
/// UI-only configuration screen for the pharmacy notification center.
class PharmacyNotificationSettingsPage extends StatefulWidget {
  const PharmacyNotificationSettingsPage({super.key});

  @override
  State<PharmacyNotificationSettingsPage> createState() =>
      _PharmacyNotificationSettingsPageState();
}

class _PharmacyNotificationSettingsPageState
    extends State<PharmacyNotificationSettingsPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  bool _scriptAlerts = true;
  bool _orderAlerts = true;
  bool _systemAlerts = true;
  bool _soundEnabled = true;
  bool _desktopPopups = true;
  String _deliveryMode = 'In-app only';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(
            selectedItemId: 'notification_settings',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Notification Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _save,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _tealBorder,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 24),
                      _sectionTitle('Delivery Channels'),
                      const SizedBox(height: 12),
                      _dropdownRow(
                        'Default delivery',
                        _deliveryMode,
                        const ['In-app only', 'Email + in-app', 'SMS + in-app'],
                        (value) => setState(() => _deliveryMode = value),
                      ),
                      _switchRow(
                        'Desktop popups',
                        'Show brief desktop alerts when a new notification arrives',
                        _desktopPopups,
                        (value) => setState(() => _desktopPopups = value),
                      ),
                      _switchRow(
                        'Sound alerts',
                        'Play a short tone for urgent notifications',
                        _soundEnabled,
                        (value) => setState(() => _soundEnabled = value),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Alert Types'),
                      const SizedBox(height: 12),
                      _switchRow(
                        'Prescription updates',
                        'Claimed, prepared, ready, and dispensed events',
                        _scriptAlerts,
                        (value) => setState(() => _scriptAlerts = value),
                      ),
                      _switchRow(
                        'Order updates',
                        'Pickup and delivery progress notifications',
                        _orderAlerts,
                        (value) => setState(() => _orderAlerts = value),
                      ),
                      _switchRow(
                        'System alerts',
                        'Sync warnings, downtime, and other operational messages',
                        _systemAlerts,
                        (value) => setState(() => _systemAlerts = value),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Quiet Hours'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _tealBorder),
                        ),
                        child: const Text(
                          'Quiet hours are a future enhancement. This UI only captures the intended pharmacy notification controls.',
                          style: TextStyle(fontSize: 13, color: _textMuted),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Notification Centre'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _tealBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inbox_outlined, color: _teal, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: const Text(
                                'View all your notifications and alert history',
                                style: const TextStyle(fontSize: 13, color: _textMuted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => context.go(AppRoutes.pharmacySettingsNotificationCenter),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _teal,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'View Centre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );
  }

  Widget _switchRow(
    String label,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _teal,
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: _textDark),
                  items: options
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (selected) {
                    if (selected != null) onChanged(selected);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        backgroundColor: Color(0xFF309CA3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'personal_information':
        context.go(AppRoutes.pharmacySettingsPersonalInfo);
        break;
      case 'pharmacy_details':
        context.go(AppRoutes.pharmacySettingsPharmacyDetails);
        break;
      case 'professional':
        context.go(AppRoutes.pharmacySettingsProfessional);
        break;
      case 'notification_settings':
      case 'preferences_notifications':
        context.go(AppRoutes.pharmacySettingsNotifications);
        break;
      case 'notification_center':
        context.go(AppRoutes.pharmacySettingsNotificationCenter);
        break;
      case 'linked_services':
        context.go(AppRoutes.pharmacySettingsLinkedServices);
        break;
      default:
        break;
    }
  }
}

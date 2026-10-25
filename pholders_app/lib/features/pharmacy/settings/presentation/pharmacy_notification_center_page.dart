import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_sidebar.dart';

class PharmacyNotificationCenterPage extends StatefulWidget {
  const PharmacyNotificationCenterPage({super.key});

  @override
  State<PharmacyNotificationCenterPage> createState() =>
      _PharmacyNotificationCenterPageState();
}

class _PharmacyNotificationCenterPageState
    extends State<PharmacyNotificationCenterPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);

  // Sample data for notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'Prescription',
      'recipient': 'John Doe',
      'message': 'Prescription #12345 is ready for pickup',
      'sentDate': '2024-06-10',
      'deliveredDate': '2024-06-10',
      'status': 'Delivered',
    },
    {
      'id': '2',
      'type': 'Order',
      'recipient': 'Jane Smith',
      'message': 'Order #67890 has been dispatched',
      'sentDate': '2024-06-09',
      'deliveredDate': '2024-06-09',
      'status': 'Delivered',
    },
    {
      'id': '3',
      'type': 'Inventory',
      'recipient': 'Pharmacy Staff',
      'message': 'Low stock alert for Paracetamol 500mg',
      'sentDate': '2024-06-08',
      'deliveredDate': '2024-06-08',
      'status': 'Delivered',
    },
    {
      'id': '4',
      'type': 'Prescription',
      'recipient': 'Robert Johnson',
      'message': 'Prescription #54321 is ready for pickup',
      'sentDate': '2024-06-07',
      'deliveredDate': '',
      'status': 'Failed',
    },
    {
      'id': '5',
      'type': 'Order',
      'recipient': 'Emily Davis',
      'message': 'Order #98765 has been dispatched',
      'sentDate': '2024-06-06',
      'deliveredDate': '',
      'status': 'Failed',
    },
  ];

  // Filter variables
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((notification) {
      // Filter by type
      if (_selectedType != 'All' && notification['type'] != _selectedType) {
        return false;
      }

      // Filter by status
      if (_selectedStatus != 'All' && notification['status'] != _selectedStatus) {
        return false;
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        final sentDate = DateTime.parse(notification['sentDate']);
        if (_startDate != null && sentDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && sentDate.isAfter(_endDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSidebar(
            selectedItemId: 'notification_center',
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
                            'Notification Center',
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
                      _sectionTitle('Notification Statistics'),
                      const SizedBox(height: 12),
                      _buildStatsCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Filters'),
                      const SizedBox(height: 12),
                      _buildFilters(),
                      const SizedBox(height: 24),
                      _sectionTitle('Notification History'),
                      const SizedBox(height: 12),
                      _buildNotificationTable(),
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

  Widget _buildStatsCard() {
    final totalSent = _filteredNotifications.length;
    final delivered = _filteredNotifications.where((n) => n['status'] == 'Delivered').length;
    final failed = _filteredNotifications.where((n) => n['status'] == 'Failed').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tealBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Sent', totalSent.toString()),
          _buildStatItem('Delivered', delivered.toString()),
          _buildStatItem('Failed', failed.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tealBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              'Type',
              _selectedType,
              ['All', 'Prescription', 'Order', 'Inventory'],
              (value) => setState(() => _selectedType = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              'Status',
              _selectedStatus,
              ['All', 'Delivered', 'Failed'],
              (value) => setState(() => _selectedStatus = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDatePicker(
              'Start Date',
              _startDate,
              (date) => setState(() => _startDate = date),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDatePicker(
              'End Date',
              _endDate,
              (date) => setState(() => _endDate = date),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _clearFilters,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Clear',
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
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _tealBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: _textDark),
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
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tealBorder),
            ),
            child: Text(
              value != null ? '${value.year}-${value.month}-${value.day}' : 'Select Date',
              style: const TextStyle(fontSize: 12, color: _textDark),
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedStatus = 'All';
      _startDate = null;
      _endDate = null;
    });
  }

  Widget _buildNotificationTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tealBorder),
      ),
      child: Column(
        children: [
          const Row(
            children: const [
              Expanded(
                flex: 1,
                child: const Text(
                  'Type',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: const Text(
                  'Recipient',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: const Text(
                  'Message',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: const Text(
                  'Sent Date',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: const Text(
                  'Status',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: const Text(
                  'Action',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_filteredNotifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No notifications found matching the selected filters.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ..._filteredNotifications.map((notification) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      notification['type'],
                      style: const TextStyle(fontSize: 12, color: _textDark),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      notification['recipient'],
                      style: const TextStyle(fontSize: 12, color: _textDark),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      notification['message'],
                      style: const TextStyle(fontSize: 12, color: _textDark),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      notification['sentDate'],
                      style: const TextStyle(fontSize: 12, color: _textDark),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      notification['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: notification['status'] == 'Delivered' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: notification['status'] == 'Failed'
                        ? InkWell(
                            onTap: () => _resendNotification(notification['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _teal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Resend',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _resendNotification(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['status'] = 'Delivered';
        _notifications[index]['deliveredDate'] = DateTime.now().toString().split(' ')[0];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification resent successfully'),
        backgroundColor: Color(0xFF309CA3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved successfully'),
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
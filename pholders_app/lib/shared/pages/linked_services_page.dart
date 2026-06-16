import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/settings_sidebar.dart';

/// Linked Services settings page — used by both doctor and pharmacy.
///
/// Layout: SettingsSidebar on the left + content on the right.
/// Shows Medical Aid, Calendar, Payments, and Communication integrations.
class LinkedServicesPage extends StatefulWidget {
  const LinkedServicesPage({super.key});

  @override
  State<LinkedServicesPage> createState() => _LinkedServicesPageState();
}

class _LinkedServicesPageState extends State<LinkedServicesPage> {
  String _selectedSettingsItem = 'linked_services';

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _bgLight = Color(0xFFE8F8F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  // ─── Mock connection state ────────────────────────────────────────────────
  final Map<String, bool> _connected = {
    'discovery': true,
    'bonitas': false,
    'momentum': false,
    'google_calendar': false,
    'outlook_calendar': true,
    'paypal': false,
    'whatsapp': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: _selectedSettingsItem,
            onMenuItemSelected: (id) {
              setState(() => _selectedSettingsItem = id);
              // TODO: navigate to the selected settings sub-page
            },
          ),
          // ── Page content ──────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                );
              },
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
          border: Border(
            bottom: BorderSide(width: 10, color: _tealBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 14),
                  _buildSection('Medical Aid', [
                    _ServiceItem(
                      id: 'discovery',
                      name: 'Discovery',
                      subtitle: 'Last synced 2 hours ago',
                      iconAsset: 'assets/discovery-icon.png',
                    ),
                    _ServiceItem(
                      id: 'bonitas',
                      name: 'Bonitas',
                      iconAsset: 'assets/bonitas-icon.png',
                    ),
                    _ServiceItem(
                      id: 'momentum',
                      name: 'Momentum',
                      iconAsset: 'assets/momentum-icon.png',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Calendar', [
                    _ServiceItem(
                      id: 'google_calendar',
                      name: 'Google Calendar',
                      subtitle: 'Last synced 5 minutes ago',
                      iconAsset: 'assets/google-calender-icon.png',
                    ),
                    _ServiceItem(
                      id: 'outlook_calendar',
                      name: 'Outlook Calendar',
                      subtitle: 'Last synced 5 minutes ago',
                      iconAsset: 'assets/outlook-icon.png',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Payments', [
                    _ServiceItem(
                      id: 'paypal',
                      name: 'PayPal',
                      subtitle: 'Last synced 4 hours ago',
                      iconAsset: 'assets/paypal-icon.png',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Communication', [
                    _ServiceItem(
                      id: 'whatsapp',
                      name: 'WhatsApp Notifications',
                      iconAsset: 'assets/whatsapp-icon.png',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildManageIntegrationsButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x14309CA3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: _teal),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Linked Services',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0x14309CA3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset('assets/edit-icon.png', width: 16, height: 16),
          ),
        ),
      ],
    );
  }

  // ─── Section ─────────────────────────────────────────────────────────────
  Widget _buildSection(String title, List<_ServiceItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FEFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) {
                return Column(
                  children: [
                    _buildServiceRow(items[index]),
                    if (index < items.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                        color: Color(0xFFE5E7EB),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow(_ServiceItem item) {
    final isConnected = _connected[item.id] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x14309CA3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              item.iconAsset,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => setState(() => _connected[item.id] = !isConnected),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isConnected ? const Color(0x15309CA3) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected ? _tealBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isConnected ? _teal : _textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Manage Integrations button ───────────────────────────────────────────
  Widget _buildManageIntegrationsButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tealBorder),
      ),
      child: const Center(
        child: Text(
          'Manage Integrations',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _ServiceItem {
  final String id;
  final String name;
  final String? subtitle;
  final String iconAsset;

  const _ServiceItem({
    required this.id,
    required this.name,
    this.subtitle,
    required this.iconAsset,
  });
}

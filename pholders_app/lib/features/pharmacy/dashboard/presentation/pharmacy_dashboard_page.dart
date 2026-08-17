import 'package:flutter/material.dart';

/// Pharmacy Dashboard matching the Figma design (node 1610:357).
///
/// Layout (content area, sidebar is handled by shell):
/// 1. Top bar: breadcrumb "Dashboard" + search bar + notification bell
/// 2. Date + Greeting row with "Scan QR Code" button
/// 3. Stats row: New Prescriptions | Pending Dispensing | Ready for Pickup | Completed
/// 4. Orders timeline section with time markers and colored cards
/// 5. Incoming Prescriptions table
class PharmacyDashboardPage extends StatelessWidget {
  const PharmacyDashboardPage({super.key});

  // ─── Colors from Figma ───────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF000000);
  static const Color _textMuted = Color(0x66000000); // rgba(0,0,0,0.4)
  static const Color _textLight = Color(0x40000000); // rgba(0,0,0,0.25)
  static const Color _sectionBorder = Color(0xFF6DD0D8);
  static const Color _orangeAccent = Color(0xA8FC9300); // rgba(252,147,0,0.66)
  static const Color _statusDotTeal = Color(0xFF6DD0D8);
  static const Color _statusDotOrange = Color(0xA8FC9300);
  static const Color _bgLight = Color(0x33309CA3); // rgba(109,208,216,0.2)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateAndGreeting(),
            const SizedBox(height: 10),
            _buildStatsSection(),
            const SizedBox(height: 10),
            _buildOrdersSection(),
            const SizedBox(height: 10),
            _buildIncomingPrescriptionsSection(),
          ],
        ),
      ),
    );
  }

  // ─── Date + Greeting + Scan QR ───────────────────────────────────────────
  Widget _buildDateAndGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Saturday, 14th March',
              style: TextStyle(
                fontSize: 11,
                color: _textMuted,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.refresh, size: 14, color: _textMuted),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Good Morning Sam',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontFamily: 'Sora',
              ),
            ),
            _buildScanQrButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildScanQrButton() {
    return Container(
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset('assets/scanner-icon.png', color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _teal,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ─── Stats Section ───────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 11, color: _sectionBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatItem('New Prescriptions', '12', 'Received today', 'assets/black-pill-icon.png')),
                      _buildVerticalDivider(),
                      Expanded(child: _buildStatItem('Pending Dispensing', '12', 'Needs Action', 'assets/dispensing-icon.png')),
                      _buildVerticalDivider(),
                      Expanded(child: _buildStatItem('Ready for Pickup', '8', 'Awaiting collection', 'assets/pickup-icon.png')),
                      _buildVerticalDivider(),
                      Expanded(child: _buildStatItem('Completed', '21', 'Dispensed today', 'assets/completed-icon.png')),
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

  Widget _buildStatItem(String label, String value, String subtitle, String iconAsset) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 28,
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(iconAsset, width: 18, height: 18),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: _textDark,
            fontFamily: 'Sora',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textDark,
            fontFamily: 'Sora',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 7,
            color: _textMuted,
            fontFamily: 'Sora',
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ─── Orders Section ──────────────────────────────────────────────────────
  Widget _buildOrdersSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 11, color: _sectionBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 39,
                height: 34,
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/orders-icon.png', width: 21, height: 21),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  fontFamily: 'Sora',
                ),
              ),
              const Spacer(),
              const Text(
                'Mar 14th',
                style: TextStyle(
                  fontSize: 11,
                  color: _textMuted,
                  fontFamily: 'Sora',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timeline
          _buildOrderTimelineItem(
            time: '08:00',
            name: 'Maria Wilson',
            medication: 'Isotretinion',
            status: 'Processing',
            displayTime: '08:20 AM',
            accentColor: _teal,
          ),
          const SizedBox(height: 6),
          _buildOrderTimelineItem(
            time: '09:00',
            name: 'Maria Wilson',
            medication: 'Isotretinion',
            status: 'Processing',
            displayTime: '09:45 AM',
            accentColor: const Color(0xFFF0181C), // red
          ),
          const SizedBox(height: 6),
          _buildOrderTimelineItem(
            time: '10:00',
            name: 'Maria Wilson',
            medication: 'Isotretinion',
            status: 'Processing',
            displayTime: '11:50 AM',
            accentColor: _orangeAccent,
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

  Widget _buildOrderTimelineItem({
    required String time,
    required String name,
    required String medication,
    required String status,
    required String displayTime,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time label
        SizedBox(
          width: 44,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _textLight,
              fontFamily: 'Sora',
            ),
          ),
        ),
        // Dot
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
          ),
        ),
        // Connector line
        Container(
          width: 30,
          height: 1,
          color: accentColor.withValues(alpha: 0.4),
        ),
        // Card
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x80309CA3).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 4, color: accentColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                      fontFamily: 'Sora',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    medication,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textLight,
                                      fontFamily: 'Sora',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _statusDotTeal,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: _textLight,
                                          fontFamily: 'Sora',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  displayTime,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: _textMuted,
                                    fontFamily: 'Sora',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _tealBorder,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                                  ),
                                  child: const Text(
                                    'Mark Ready',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'SF Pro',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Incoming Prescriptions Section ──────────────────────────────────────
  Widget _buildIncomingPrescriptionsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 11, color: _sectionBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 39,
                height: 34,
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/incoming-prescriptions-icon.png', width: 21, height: 21),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Incoming Prescriptions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  fontFamily: 'Sora',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Divider line
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          // Table header
          _buildTableHeader(),
          const SizedBox(height: 6),
          // Table rows
          _buildPrescriptionRow(
            patient: 'Maria Wilson',
            doctor: 'Dr Sam Smith',
            medication: 'Panado',
            date: '01 Mar',
            status: 'New',
            statusColor: _statusDotOrange,
          ),
          const SizedBox(height: 4),
          _buildPrescriptionRow(
            patient: 'Maria Wilson',
            doctor: 'Dr Sam Smith',
            medication: 'Panado',
            date: '01 Mar',
            status: 'New',
            statusColor: _statusDotOrange,
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

  Widget _buildTableHeader() {
    return const Row(
      children: [
        Expanded(flex: 2, child: _HeaderText('Patient')),
        Expanded(flex: 2, child: _HeaderText('Doctor')),
        Expanded(flex: 2, child: _HeaderText('Medication')),
        Expanded(flex: 1, child: _HeaderText('Date')),
        Expanded(flex: 1, child: _HeaderText('Status')),
        Expanded(flex: 1, child: _HeaderText('Action')),
      ],
    );
  }

  Widget _buildPrescriptionRow({
    required String patient,
    required String doctor,
    required String medication,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Patient with avatar
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgLight,
                    border: Border.all(color: _teal, width: 1),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 14,
                    color: _teal,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  patient,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    fontFamily: 'Sora',
                  ),
                ),
              ],
            ),
          ),
          // Doctor
          Expanded(
            flex: 2,
            child: Text(
              doctor,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textMuted,
                fontFamily: 'Sora',
              ),
            ),
          ),
          // Medication
          Expanded(
            flex: 2,
            child: Text(
              medication,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textMuted,
                fontFamily: 'Sora',
              ),
            ),
          ),
          // Date
          Expanded(
            flex: 1,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textMuted,
                fontFamily: 'Sora',
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _textLight,
                    fontFamily: 'Sora',
                  ),
                ),
              ],
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _tealBorder,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SF Pro',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0x66000000), // rgba(0,0,0,0.4)
        fontFamily: 'Sora',
      ),
    );
  }
}

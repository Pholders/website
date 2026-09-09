import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pharmacy Prescriptions page matching the Figma design.
///
/// Shows a filterable table of prescriptions with status tabs
/// (All, New, Accepted, In-Progress, Ready, Dispensed) and
/// context-sensitive action buttons per row.
class PharmacyPrescriptionsPage extends StatefulWidget {
  const PharmacyPrescriptionsPage({super.key});

  @override
  State<PharmacyPrescriptionsPage> createState() =>
      _PharmacyPrescriptionsPageState();
}

class _PharmacyPrescriptionsPageState extends State<PharmacyPrescriptionsPage> {
  int _selectedTab = 0;

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealLight = Color(0xFFE8F8F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFD1F5F5);

  // Status colors
  static const Color _newColor = Color(0xFFFBBF24);
  static const Color _acceptedColor = Color(0xFF3B82F6);
  static const Color _inProgressColor = Color(0xFFF97316);
  static const Color _readyColor = Color(0xFF34D399);
  static const Color _dispensedColor = Color(0xFF9CA3AF);

  final List<String> _tabs = [
    'All',
    'New',
    'Accepted',
    'In-Progress',
    'Ready',
    'Dispensed',
  ];

  // Mock data
  final List<_PrescriptionData> _prescriptions = const [
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'New',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Accepted',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'In-Progress',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Ready',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
    _PrescriptionData(
      patient: 'Maria Wilson',
      doctor: 'Dr Sara Smith',
      medication: 'Panado',
      date: '01 Mar',
      status: 'Dispensed',
    ),
  ];

  List<_PrescriptionData> get _filteredPrescriptions {
    final tab = _tabs[_selectedTab];
    if (tab == 'All') return _prescriptions;
    return _prescriptions.where((p) => p.status == tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescriptions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage incoming prescriptions and dispensing',
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
        _buildScanQrButton(),
      ],
    );
  }

  Widget _buildScanQrButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x33309CA3),
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
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        ...List.generate(_tabs.length, (index) {
          final isActive = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : _textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        const Text(
          'Total: 140',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  // ─── Table ───────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final data = _filteredPrescriptions;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: _ColHeader('Patient')),
                        Expanded(flex: 3, child: _ColHeader('Doctor')),
                        Expanded(flex: 3, child: _ColHeader('Medication')),
                        Expanded(flex: 2, child: _ColHeader('Date')),
                        Expanded(flex: 2, child: _ColHeader('Status')),
                        Expanded(flex: 2, child: _ColHeader('Action')),
                      ],
                    ),
                  ),
                  // Table rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) => _buildRow(data[index]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_PrescriptionData rx) {
    return InkWell(
      onTap: () {
        // Navigate to prescription detail with a mock ID
        context.go('/pharmacy/prescriptions/rx-${rx.patient.hashCode.abs()}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
      child: Row(
        children: [
          // Patient
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x33309CA3),
                    border: Border.all(color: _teal, width: 1),
                  ),
                  child: const Icon(Icons.person, size: 14, color: _teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rx.patient,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Doctor
          Expanded(
            flex: 3,
            child: Text(
              rx.doctor,
              style: const TextStyle(fontSize: 13, color: _textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Medication
          Expanded(
            flex: 3,
            child: Text(
              rx.medication,
              style: const TextStyle(fontSize: 13, color: _textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              rx.date,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _StatusBadge(status: rx.status),
          ),
          // Action
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ActionButton(status: rx.status),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _dotColor {
    switch (status) {
      case 'New':
        return _PharmacyPrescriptionsPageState._newColor;
      case 'Accepted':
        return _PharmacyPrescriptionsPageState._acceptedColor;
      case 'In-Progress':
        return _PharmacyPrescriptionsPageState._inProgressColor;
      case 'Ready':
        return _PharmacyPrescriptionsPageState._readyColor;
      case 'Dispensed':
        return _PharmacyPrescriptionsPageState._dispensedColor;
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _dotColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: _dotColor,
          ),
        ),
      ],
    );
  }
}

/// Action button that changes based on prescription status.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.status});
  final String status;

  String get _label {
    switch (status) {
      case 'New':
        return 'Accept';
      case 'Accepted':
        return 'Process';
      case 'In-Progress':
        return 'Dispense';
      case 'Ready':
        return 'Complete';
      case 'Dispensed':
        return 'Complete';
      default:
        return 'View';
    }
  }

  Color get _bgColor {
    switch (status) {
      case 'New':
        return const Color(0xFF6DD0D8);
      case 'Accepted':
        return const Color(0xFF6DD0D8);
      case 'In-Progress':
        return const Color(0xFF6DD0D8);
      case 'Ready':
      case 'Dispensed':
        return const Color(0xFF6DD0D8);
      default:
        return const Color(0xFF6DD0D8);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'New':
      case 'Accepted':
      case 'In-Progress':
      case 'Ready':
      case 'Dispensed':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _PrescriptionData {

  const _PrescriptionData({
    required this.patient,
    required this.doctor,
    required this.medication,
    required this.date,
    required this.status,
  });
  final String patient;
  final String doctor;
  final String medication;
  final String date;
  final String status;
}

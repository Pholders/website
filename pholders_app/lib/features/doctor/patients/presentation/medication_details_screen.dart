import 'package:flutter/material.dart';
import 'package:pholders_app/features/doctor/patients/presentation/medication_screen.dart';

// ─── Medication Details Screen ────────────────────────────────────────────────
class MedicationDetailsScreen extends StatefulWidget {
  final MedHistoryItem item;
  final VoidCallback onBack;

  const MedicationDetailsScreen({
    super.key,
    required this.item,
    required this.onBack,
  });

  @override
  State<MedicationDetailsScreen> createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Container(
            color: MedColors.bg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileTabs(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_rounded,
                    color: MedColors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Medication details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MedColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: MedColors.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MedColors.border),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for patient name, ID, or prescription...',
                  hintStyle: TextStyle(
                      color: MedColors.textSecondary, fontSize: 12),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: MedColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: MedColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MedColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile tabs (same as patient profile) ────────────────────────────────
  Widget _buildProfileTabs() {
    final tabs = [
      'Patient profile',
      'Medication',
      'Prescriptions',
      'Appointments',
      'Documents',
      'History',
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final active = i == 1; // Medication tab always active here
        return Container(
          margin: const EdgeInsets.only(right: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? MedColors.teal : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            tabs[i],
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? MedColors.teal
                  : MedColors.textSecondary,
            ),
          ),
        );
      }),
    );
  }

  // ── Details card ──────────────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: MedColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MedColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Edit icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MedColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MedColors.border),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: MedColors.textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detail fields
          _DetailField(
            label: 'Medication',
            value: widget.item.medication,
          ),
          const SizedBox(height: 14),
          _DetailField(
            label: 'Dosage',
            value: widget.item.dosage,
          ),
          const SizedBox(height: 14),
          _DetailField(
            label: 'Frequency',
            value: widget.item.frequency,
          ),
          const SizedBox(height: 14),
          _DetailField(
            label: 'Duration',
            value: widget.item.duration,
          ),
          const SizedBox(height: 14),

          // Status field
          _DetailFieldWidget(
            label: 'Status',
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: widget.item.isActive
                    ? MedColors.activeBg
                    : MedColors.stoppedBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.item.isActive
                          ? MedColors.teal
                          : MedColors.stoppedText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.item.isActive ? 'Active' : 'Stopped',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.item.isActive
                          ? MedColors.teal
                          : MedColors.stoppedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DetailField(
            label: 'Adherence',
            value: '${widget.item.adherence}%',
          ),
        ],
      ),
    );
  }
}

// ─── Detail field (text value) ────────────────────────────────────────────────
class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: MedColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MedColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MedColors.border),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: MedColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Detail field (custom widget value e.g. status badge) ────────────────────
class _DetailFieldWidget extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailFieldWidget({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: MedColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: MedColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MedColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

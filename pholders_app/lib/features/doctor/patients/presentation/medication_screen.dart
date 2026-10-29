import 'package:flutter/material.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;

const _teal = Color(0xFF2EC4C4);
const _tealLight = Color(0xFFE6F7F7);
const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);

/// The Medication tab of a patient's profile: what the patient is currently
/// taking, from their health record. Booking this doctor is what shares it.
///
/// It used to show invented clinical data under whichever real patient was
/// open: two Amoxicillin courses, four Isotretinoin rows with an 85%
/// adherence figure, and a "medical history" of heart disease, liposuction
/// and diabetic complications.
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key, required this.patient, this.repository});

  final Patient patient;
  final PatientRecordRepository? repository;

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  List<PatientMedication> _medications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final medications = await _repo.fetchMedications(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _medications = medications;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_outlined, size: 18, color: _teal),
                const SizedBox(width: 8),
                const Text('Current medication',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                const Spacer(),
                if (!_loading)
                  IconButton(
                    tooltip: 'Refresh',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 18, color: _textSecondary),
                    onPressed: _load,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
          ),
        ),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!,
              style: const TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }
    if (_medications.isEmpty) {
      return const Text(
        'No current medication on the patient\'s record. Prescriptions you '
        'write for them are on the Prescriptions tab.',
        style: TextStyle(fontSize: 13, height: 1.5, color: _textSecondary),
      );
    }
    return Column(
      children: [for (final m in _medications) _MedicationRow(medication: m)],
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.medication});
  final PatientMedication medication;

  static String _day(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final how = [m.dosage, m.frequency, m.route].whereType<String>().join(' · ');
    final start = m.startDate;
    final end = m.endDate;
    final when = start == null
        ? null
        : end == null
            ? 'Since ${_day(start)}'
            : '${_day(start)} – ${_day(end)}';
    final details = [
      if (when != null) when,
      if (m.reason != null) 'For ${m.reason}',
      if (m.prescribedBy != null) 'Prescribed by ${m.prescribedBy}',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_rounded, size: 18, color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                if (how.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(how,
                      style: const TextStyle(fontSize: 13, color: _textPrimary)),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(details,
                      style:
                          const TextStyle(fontSize: 12, color: _textSecondary)),
                ],
                if (m.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(m.notes!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: _textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

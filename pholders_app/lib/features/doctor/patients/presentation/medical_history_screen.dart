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

/// The History tab of a patient's profile: their completed visits and
/// prescriptions with every doctor on the platform, newest first. Read-only.
///
/// It used to show fourteen invented entries, and "Add note" only added to
/// the list on screen, so a note was gone after a refresh. There is nowhere
/// on the server to keep a doctor's note yet, so the button is not offered.
class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key, required this.patient, this.repository});

  final Patient patient;
  final PatientRecordRepository? repository;

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  List<PatientHistoryEntry> _entries = const [];
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
      final entries = await _repo.fetchHistory(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _entries = entries;
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
                const Icon(Icons.history_rounded, size: 18, color: _teal),
                const SizedBox(width: 8),
                const Text('Visits and prescriptions',
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
    if (_entries.isEmpty) {
      return const Text(
        'No completed visits or prescriptions on the patient\'s record yet.',
        style: TextStyle(fontSize: 13, color: _textSecondary),
      );
    }
    return Column(
      children: [for (final e in _entries) _HistoryRow(entry: e)],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final PatientHistoryEntry entry;

  static String _day(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _label(String? s) {
    if (s == null || s.isEmpty) return '';
    final words = s.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isVisit = e.kind == 'appointment';
    final who = [
      if (e.providerName != null) 'Dr ${e.providerName}',
      if (e.specialization != null) e.specialization!,
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
            child: Icon(
                isVisit ? Icons.event_available_outlined : Icons.description_outlined,
                size: 18,
                color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVisit ? 'Visit' : 'Prescription',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary),
                ),
                if (e.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(e.notes!,
                      style: const TextStyle(fontSize: 13, color: _textPrimary)),
                ],
                if (who.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(who,
                      style:
                          const TextStyle(fontSize: 12, color: _textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (e.date != null)
                Text(_day(e.date!),
                    style: const TextStyle(fontSize: 12, color: _textSecondary)),
              if (e.status != null) ...[
                const SizedBox(height: 2),
                Text(_label(e.status),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _teal)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart'
    show AppProfileColors;

/// The vitals a patient logged themselves, shown once they let this doctor
/// see their health record. Until then: a way to ask, and where the
/// request stands.
///
/// Readings are shown as the patient typed them. Nothing here labels one as
/// normal or abnormal: they are self-measured, and the SRS keeps clinical
/// alerting out of scope.
class PatientVitalsPanel extends StatefulWidget {
  const PatientVitalsPanel({
    super.key,
    required this.patientId,
    this.repository,
  });

  final String patientId;
  final PatientRecordRepository? repository;

  @override
  State<PatientVitalsPanel> createState() => _PatientVitalsPanelState();
}

class _PatientVitalsPanelState extends State<PatientVitalsPanel> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  RecordAccess? _access;
  List<PatientVital> _vitals = const [];
  bool _loading = true;
  bool _asking = false;
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
      final access = await _repo.fetchAccess(widget.patientId);
      var vitals = const <PatientVital>[];
      if (access.status == RecordAccessStatus.granted) {
        vitals = await _repo.fetchVitals(widget.patientId);
      }
      if (!mounted) return;
      setState(() {
        _access = access;
        _vitals = vitals;
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

  Future<void> _ask() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _AskDialog(),
    );
    if (reason == null || !mounted) return;
    setState(() => _asking = true);
    try {
      final access = await _repo.requestAccess(widget.patientId, reason: reason);
      if (!mounted) return;
      setState(() {
        _access = access;
        _asking = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _asking = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppProfileColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 18, color: AppProfileColors.teal),
              const SizedBox(width: 8),
              const Text('Vitals',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppProfileColors.textPrimary)),
              const Spacer(),
              if (!_loading)
                IconButton(
                  tooltip: 'Refresh',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppProfileColors.textSecondary),
                  onPressed: _load,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _body(),
        ],
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
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppProfileColors.teal),
          ),
        ),
      );
    }
    if (_error != null) {
      return _Message(
        text: _error!,
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }

    final access = _access!;
    switch (access.status) {
      case RecordAccessStatus.granted:
        return _vitals.isEmpty
            ? const _Message(
                text: 'The patient has not logged any vitals yet.')
            : _VitalsView(vitals: _vitals);
      case RecordAccessStatus.pending:
        return _Message(
          text: 'You asked to see this patient’s health record'
              '${access.requestedAt == null ? '' : ' on ${_day(access.requestedAt!)}'}. '
              'Their vitals appear here once they allow it in the Pholders app.',
        );
      case RecordAccessStatus.denied:
      case RecordAccessStatus.revoked:
      case RecordAccessStatus.none:
        final lead = switch (access.status) {
          RecordAccessStatus.denied =>
            'The patient declined your last request to see their health record.',
          RecordAccessStatus.revoked =>
            'The patient no longer shares their health record with you.',
          _ => 'Vitals are part of the patient’s own health record, which '
              'they choose who may see.',
        };
        return _Message(
          text: access.canRequest
              ? '$lead You can ask them for access.'
              : lead,
          action: access.canRequest
              ? FilledButton.icon(
                  onPressed: _asking ? null : _ask,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppProfileColors.teal),
                  icon: _asking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text(access.status == RecordAccessStatus.none
                      ? 'Ask for access'
                      : 'Ask again'),
                )
              : null,
        );
    }
  }
}

String _day(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _dayTime(DateTime d) =>
    '${_day(d)}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String? _fmt(double? v) {
  if (v == null) return null;
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 13, height: 1.5, color: AppProfileColors.textSecondary)),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    );
  }
}

class _VitalsView extends StatelessWidget {
  const _VitalsView({required this.vitals});

  /// Newest first.
  final List<PatientVital> vitals;

  ({String value, DateTime at})? _latest(String? Function(PatientVital v) pick) {
    for (final v in vitals) {
      final s = pick(v);
      if (s != null) return (value: s, at: v.measuredAt);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, String, String? Function(PatientVital))>[
      ('Blood pressure', 'mmHg', (v) => v.bloodPressure),
      ('Heart rate', 'bpm', (v) => v.heartRate?.toString()),
      ('Weight', 'kg', (v) => _fmt(v.weightKg)),
      ('BMI', '', (v) => _fmt(v.bmi)),
      ('Blood glucose', 'mmol/L', (v) => _fmt(v.bloodGlucose)),
      ('Oxygen', '%', (v) => _fmt(v.oxygenSaturation)),
      ('Temperature', '°C', (v) => _fmt(v.temperatureC)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, unit, pick) in tiles)
              if (_latest(pick) case final latest?)
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppProfileColors.tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11, color: AppProfileColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: latest.value,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppProfileColors.textPrimary)),
                        if (unit.isNotEmpty)
                          TextSpan(
                              text: ' $unit',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppProfileColors.textSecondary)),
                      ])),
                      const SizedBox(height: 4),
                      Text(_day(latest.at),
                          style: const TextStyle(
                              fontSize: 10, color: AppProfileColors.textSecondary)),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Text('All readings (${vitals.length})',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppProfileColors.textPrimary)),
        const SizedBox(height: 6),
        for (final v in vitals.take(20))
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppProfileColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(_dayTime(v.measuredAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppProfileColors.textSecondary)),
                ),
                Expanded(
                  child: Text(
                    [
                      if (v.bloodPressure != null) 'BP ${v.bloodPressure}',
                      if (v.heartRate != null) 'HR ${v.heartRate} bpm',
                      if (v.weightKg != null) '${_fmt(v.weightKg)} kg',
                      if (v.bloodGlucose != null) 'Glucose ${_fmt(v.bloodGlucose)} mmol/L',
                      if (v.oxygenSaturation != null) 'SpO₂ ${_fmt(v.oxygenSaturation)}%',
                      if (v.temperatureC != null) '${_fmt(v.temperatureC)} °C',
                      if (v.notes != null) '“${v.notes}”',
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: AppProfileColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Logged by the patient from their own measurements.',
          style: TextStyle(fontSize: 11, color: AppProfileColors.textSecondary),
        ),
      ],
    );
  }
}

class _AskDialog extends StatefulWidget {
  const _AskDialog();

  @override
  State<_AskDialog> createState() => _AskDialogState();
}

class _AskDialogState extends State<_AskDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ask to see their health record'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The patient gets a notification and chooses whether to share '
              'their record, including their vitals, with you.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Why (optional, shown to the patient)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          style: FilledButton.styleFrom(backgroundColor: AppProfileColors.teal),
          child: const Text('Send request'),
        ),
      ],
    );
  }
}

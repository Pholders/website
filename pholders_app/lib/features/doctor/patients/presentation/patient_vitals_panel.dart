import 'package:flutter/material.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart'
    show AppProfileColors;

/// The Vitals tab of a patient's profile.
///
/// Vitals are taken by the doctor at a consultation; the patient only views
/// them. Booking a doctor is what shares them, so any doctor with a booking
/// sees every reading, including ones another doctor took, and can record a
/// new one. There is no access request to wait on.
///
/// Readings are shown as recorded. Nothing here labels one as normal or
/// abnormal; the SRS keeps clinical alerting out of scope.
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

  List<PatientVital> _vitals = const [];
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
      final vitals = await _repo.fetchVitals(widget.patientId);
      if (!mounted) return;
      setState(() {
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

  Future<void> _record() async {
    final saved = await showDialog<PatientVital>(
      context: context,
      builder: (_) => _RecordVitalsDialog(
        save: (values) => _repo.recordVitals(widget.patientId, values),
      ),
    );
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Vitals recorded')));
    // Reload rather than insert: the server works out BMI and who recorded it.
    await _load();
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
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading || _error != null ? null : _record,
                style: FilledButton.styleFrom(
                    backgroundColor: AppProfileColors.teal),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Record vitals'),
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
    return _vitals.isEmpty
        ? const _Message(
            text: 'No vitals recorded yet. Use “Record vitals” to add the '
                'readings you take at this consultation.')
        : _VitalsView(vitals: _vitals);
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
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: Text(
                    // Readings from before doctors took over recording were
                    // typed in by the patient and have no doctor.
                    v.recordedByName ?? 'Logged by the patient',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11, color: AppProfileColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One measurement in the record form. The limits mirror the backend's
/// services/vitalsService.js, so a typo is caught before the round trip; the
/// server still checks and its message is shown if it disagrees.
class _Field {
  const _Field(this.key, this.label, this.unit, this.min, this.max,
      {this.integer = false});
  final String key;
  final String label;
  final String unit;
  final num min;
  final num max;
  final bool integer;
}

const _fields = <_Field>[
  _Field('systolic_bp', 'Systolic BP', 'mmHg', 50, 260, integer: true),
  _Field('diastolic_bp', 'Diastolic BP', 'mmHg', 30, 160, integer: true),
  _Field('heart_rate', 'Heart rate', 'bpm', 25, 250, integer: true),
  _Field('temperature_c', 'Temperature', '°C', 30, 45),
  _Field('oxygen_saturation', 'Oxygen saturation', '%', 50, 100),
  _Field('blood_glucose', 'Blood glucose', 'mmol/L', 1, 40),
  _Field('weight_kg', 'Weight', 'kg', 1, 350),
  _Field('height_cm', 'Height', 'cm', 40, 250),
];

class _RecordVitalsDialog extends StatefulWidget {
  const _RecordVitalsDialog({required this.save});

  final Future<PatientVital> Function(Map<String, dynamic> values) save;

  @override
  State<_RecordVitalsDialog> createState() => _RecordVitalsDialogState();
}

class _RecordVitalsDialogState extends State<_RecordVitalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final f in _fields) f.key: TextEditingController(),
  };
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  String? _validate(_Field f, String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = num.tryParse(text.replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    if (f.integer && n != n.roundToDouble()) return 'Whole number';
    if (n < f.min || n > f.max) return '${f.min}–${f.max} ${f.unit}';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final values = <String, dynamic>{};
    for (final f in _fields) {
      final text = _controllers[f.key]!.text.trim().replaceAll(',', '.');
      if (text.isNotEmpty) values[f.key] = num.parse(text);
    }
    final hasMeasurement = values.keys.any((k) => k != 'height_cm');
    if (!hasMeasurement) {
      setState(() => _error = 'Enter at least one reading.');
      return;
    }
    if (values.containsKey('systolic_bp') != values.containsKey('diastolic_bp')) {
      setState(() => _error = 'Enter both blood pressure numbers, or neither.');
      return;
    }
    final notes = _notes.text.trim();
    if (notes.isNotEmpty) values['notes'] = notes;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.save(values);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record vitals'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fill in what you measured; leave the rest blank. The '
                  'patient sees these in their app.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final f in _fields)
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: _controllers[f.key],
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) => _validate(f, v),
                          decoration: InputDecoration(
                            labelText: f.label,
                            suffixText: f.unit,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  enabled: !_saving,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppProfileColors.teal),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

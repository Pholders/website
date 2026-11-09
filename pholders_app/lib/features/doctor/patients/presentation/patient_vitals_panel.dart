import 'package:flutter/material.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patient_profile_screen.dart'
    show AppProfileColors;
import 'package:pholders_app/features/doctor/patients/presentation/record_card.dart';

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
    final kinds = await _repo.fetchVitalKinds();
    if (!mounted) return;
    double? last(double? Function(PatientVital v) pick) {
      for (final v in _vitals) {
        final value = pick(v);
        if (value != null) return value;
      }
      return null;
    }

    final saved = await showDialog<PatientVital>(
      context: context,
      builder: (_) => _RecordVitalsDialog(
        kinds: kinds,
        lastWeightKg: last((v) => v.weightKg),
        lastHeightCm: last((v) => v.heightCm),
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
    return RecordCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Vitals',
      subtitle: 'Readings taken at consultations, newest first',
      trailing: RecordAction(
        label: 'Record vitals',
        onTap: _loading || _error != null ? null : _record,
      ),
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const RecordMessage();
    if (_error != null) {
      return RecordMessage(
        text: _error,
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }
    return _vitals.isEmpty
        ? const RecordMessage(
            text: 'No vitals recorded yet. Use “Record vitals” to add the '
                'readings you take at this consultation.')
        : _VitalsView(vitals: _vitals);
  }
}

String _day(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _dayTime(DateTime d) =>
    '${_day(d)}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String? _fmt(double? v) {
  if (v == null) return null;
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

class _VitalsView extends StatelessWidget {
  const _VitalsView({required this.vitals});

  /// Newest first.
  final List<PatientVital> vitals;

  ({String value, DateTime at})? _latest(
      String? Function(PatientVital v) pick) {
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
      ('Pulse', 'bpm', (v) => v.heartRate?.toString()),
      ('Weight', 'kg', (v) => _fmt(v.weightKg)),
      ('Height', 'cm', (v) => _fmt(v.heightCm)),
      ('BMI', '', (v) => _fmt(v.bmi)),
      ('Blood glucose', 'mmol/L', (v) => _fmt(v.bloodGlucose)),
      ('Oxygen', '%', (v) => _fmt(v.oxygenSaturation)),
      ('Temperature', '°C', (v) => _fmt(v.temperatureC)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Latest',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RecordColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, unit, pick) in tiles)
              if (_latest(pick) case final latest?)
                Container(
                  width: 160,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: RecordColors.pale,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RecordColors.paleEdge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13, color: RecordColors.muted)),
                      const SizedBox(height: 6),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: latest.value,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: RecordColors.ink)),
                        if (unit.isNotEmpty)
                          TextSpan(
                              text: ' $unit',
                              style: const TextStyle(
                                  fontSize: 12, color: RecordColors.muted)),
                      ])),
                      const SizedBox(height: 6),
                      Text(_day(latest.at),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RecordColors.label)),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: 20),
        Text('All readings (${vitals.length})',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RecordColors.ink)),
        const SizedBox(height: 10),
        for (final v in vitals.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecordTile(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(_dayTime(v.measuredAt),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: RecordColors.ink)),
                  ),
                  Expanded(
                    child: Text(
                      [
                        if (v.bloodPressure != null) 'BP ${v.bloodPressure}',
                        if (v.heartRate != null) 'Pulse ${v.heartRate} bpm',
                        if (v.weightKg != null) '${_fmt(v.weightKg)} kg',
                        if (v.heightCm != null) '${_fmt(v.heightCm)} cm',
                        if (v.bmi != null) 'BMI ${_fmt(v.bmi)}',
                        if (v.bloodGlucose != null)
                          'Glucose ${_fmt(v.bloodGlucose)} mmol/L',
                        if (v.oxygenSaturation != null)
                          'SpO₂ ${_fmt(v.oxygenSaturation)}%',
                        if (v.temperatureC != null)
                          '${_fmt(v.temperatureC)} °C',
                        if (v.notes != null) '“${v.notes}”',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 13, color: RecordColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: Text(
                      // Readings from before doctors took over recording
                      // were typed in by the patient and have no doctor.
                      v.recordedByName ?? 'Logged by the patient',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12, color: RecordColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// BMI from weight in kg and height in cm, rounded as the server does.
double? bmiOf(double? weightKg, double? heightCm) {
  if (weightKg == null || heightCm == null || heightCm <= 0) return null;
  final m = heightCm / 100;
  return (weightKg / (m * m) * 100).round() / 100;
}

/// The record form. Blood pressure, pulse and weight are always on it, as a
/// consultation records them as a rule; the doctor adds height, temperature
/// and the rest when measured (Prince, 9 Nov). The list and its limits come
/// from the server, so a typo is caught before the round trip; the server
/// still checks and its message is shown if it disagrees.
class _RecordVitalsDialog extends StatefulWidget {
  const _RecordVitalsDialog({
    required this.kinds,
    required this.save,
    this.lastWeightKg,
    this.lastHeightCm,
  });

  final List<VitalKindDef> kinds;
  final Future<PatientVital> Function(Map<String, dynamic> values) save;

  /// The latest on record, for the BMI preview when only one is taken today.
  final double? lastWeightKg;
  final double? lastHeightCm;

  @override
  State<_RecordVitalsDialog> createState() => _RecordVitalsDialogState();
}

class _RecordVitalsDialogState extends State<_RecordVitalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final k in widget.kinds)
      for (final f in k.fields) f.key: TextEditingController()..addListener(_refresh),
  };
  final _notes = TextEditingController();

  /// Kinds on the form: the defaults, then whatever the doctor added.
  late final List<String> _shown = [
    for (final k in widget.kinds)
      if (k.isDefault) k.key,
  ];
  bool _saving = false;
  String? _error;

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  VitalKindDef _kind(String key) => widget.kinds.firstWhere((k) => k.key == key);

  double? _entered(String key) =>
      double.tryParse(_controllers[key]?.text.trim().replaceAll(',', '.') ?? '');

  String? _validate(VitalFieldDef f, String unit, String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = num.tryParse(text.replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    if (f.integer && n != n.roundToDouble()) return 'Whole number';
    if (n < f.min || n > f.max) return '${f.min}–${f.max} $unit';
    return null;
  }

  void _add(String key) => setState(() => _shown.add(key));

  void _remove(VitalKindDef kind) => setState(() {
        _shown.remove(kind.key);
        for (final f in kind.fields) {
          _controllers[f.key]!.clear();
        }
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final values = <String, dynamic>{};
    for (final key in _shown) {
      for (final f in _kind(key).fields) {
        final text = _controllers[f.key]!.text.trim().replaceAll(',', '.');
        if (text.isNotEmpty) values[f.key] = num.parse(text);
      }
    }
    if (values.isEmpty) {
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

  /// "BMI 26.5" with where each figure came from, or a hint how to get one.
  String? _bmiLine() {
    final hasHeightKind = widget.kinds.any((k) => k.key == 'height_cm');
    final weightToday = _entered('weight_kg');
    final heightToday = _shown.contains('height_cm') ? _entered('height_cm') : null;
    if (weightToday == null && heightToday == null) return null;
    final weight = weightToday ?? widget.lastWeightKg;
    final height = heightToday ?? widget.lastHeightCm;
    final bmi = bmiOf(weight, height);
    if (bmi == null) {
      if (height == null && hasHeightKind && !_shown.contains('height_cm')) {
        return 'Add height to work out the BMI.';
      }
      return null;
    }
    final from = [
      if (weightToday == null) 'last weight',
      if (heightToday == null) 'last height',
    ];
    return 'BMI ${bmi.toStringAsFixed(1)}'
        '${from.isEmpty ? '' : ' (using the ${from.join(' and ')} on record)'}';
  }

  Widget _kindRow(VitalKindDef kind) {
    return Padding(
      key: ValueKey('vital-${kind.key}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in kind.fields) ...[
            Expanded(
              child: TextFormField(
                key: ValueKey('field-${f.key}'),
                controller: _controllers[f.key],
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validate(f, kind.unit, v),
                decoration: InputDecoration(
                  labelText: f.label,
                  suffixText: kind.unit,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 36,
            child: kind.isDefault
                ? null
                : IconButton(
                    tooltip: 'Remove ${kind.label.toLowerCase()}',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _saving ? null : () => _remove(kind),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addable = widget.kinds.where((k) => !_shown.contains(k.key)).toList();
    final bmi = _bmiLine();
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
                  'Blood pressure, pulse and weight are taken at most visits. '
                  'Add anything else you measured. Leave blank what you did '
                  'not take. The patient sees these in their app.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                for (final key in _shown) _kindRow(_kind(key)),
                if (addable.isNotEmpty) ...[
                  const Text('Add a vital',
                      style: TextStyle(fontSize: 12, color: RecordColors.muted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in addable)
                        ActionChip(
                          key: ValueKey('add-${k.key}'),
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(k.label),
                          onPressed: _saving ? null : () => _add(k.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (bmi != null) ...[
                  Text(bmi,
                      key: const ValueKey('bmi-preview'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: RecordColors.ink)),
                  const SizedBox(height: 12),
                ],
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

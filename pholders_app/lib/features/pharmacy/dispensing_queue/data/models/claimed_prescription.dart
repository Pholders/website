import 'package:equatable/equatable.dart';

/// A prescription a patient has claimed at this pharmacy, waiting to be
/// dispensed.
///
/// Shape from `GET /prescriptions/pharmacy/claimed`. A script only appears
/// here once the patient has sent it to this pharmacy — claiming is what
/// hands it over, and it can only go to one.
class ClaimedPrescription extends Equatable {
  const ClaimedPrescription({
    required this.id,
    required this.number,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.diagnosis,
    this.claimedAt,
    this.medicines = const [],
  });

  factory ClaimedPrescription.fromJson(Map<String, dynamic> json) {
    final rawMedicines = json['medicines'];
    return ClaimedPrescription(
      id: _asInt(json['prescriptionId']) ?? 0,
      number: _asString(json['prescriptionNumber']) ?? '',
      patientName: _asString(json['patientName']) ?? 'Unknown patient',
      patientEmail: _asString(json['patientEmail']),
      patientPhone: _asString(json['patientPhone']),
      diagnosis: _asString(json['diagnosis']),
      claimedAt: DateTime.tryParse(_asString(json['claimedAt']) ?? ''),
      medicines: rawMedicines is List
          ? rawMedicines
              .whereType<Map<String, dynamic>>()
              .map(DispensableMedicine.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String number;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? diagnosis;
  final DateTime? claimedAt;
  final List<DispensableMedicine> medicines;

  /// "Paracetamol, Amoxicillin" for the row, or a count when there are many.
  String get medicineSummary {
    if (medicines.isEmpty) return 'No medicines listed';
    if (medicines.length <= 2) {
      return medicines.map((m) => m.name).join(', ');
    }
    return '${medicines.first.name} +${medicines.length - 1} more';
  }

  /// "08:20" — the pharmacy sorts its day by when a script arrived.
  String get claimedTime {
    final at = claimedAt?.toLocal();
    if (at == null) return '';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, number, patientName, claimedAt];

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }
}

/// One line on a claimed prescription.
class DispensableMedicine extends Equatable {
  const DispensableMedicine({
    required this.name,
    this.dosage,
    this.quantity,
    this.frequency,
    this.instructions,
  });

  factory DispensableMedicine.fromJson(Map<String, dynamic> json) {
    return DispensableMedicine(
      name: ClaimedPrescription._asString(
              json['name'] ?? json['medicine_name']) ??
          'Unnamed medicine',
      dosage: ClaimedPrescription._asString(json['dosage']),
      quantity: ClaimedPrescription._asInt(json['quantity']),
      frequency: ClaimedPrescription._asString(json['frequency']),
      instructions: ClaimedPrescription._asString(
          json['instructions'] ?? json['special_instructions']),
    );
  }

  final String name;
  final String? dosage;
  final int? quantity;
  final String? frequency;
  final String? instructions;

  /// "500mg · 20 · four times daily"
  String get detail => [
        if (dosage != null) dosage,
        if (quantity != null) '$quantity',
        if (frequency != null) frequency,
      ].whereType<String>().join(' · ');

  @override
  List<Object?> get props => [name, dosage, quantity, frequency];
}

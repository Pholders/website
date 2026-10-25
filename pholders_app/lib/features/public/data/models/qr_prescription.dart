import 'package:equatable/equatable.dart';

/// A prescription opened through its one-time QR link.
///
/// Shape from `GET /prescriptions/qr/:token`, which is unauthenticated by
/// design: whoever holds the link holds the prescription.
class QrPrescription extends Equatable {
  const QrPrescription({
    required this.number,
    required this.medicines,
    this.prescriberName,
    this.prescriberHpcsa,
    this.prescriberPhone,
    this.patientName,
    this.diagnosis,
    this.clinicalNotes,
    this.signedAt,
    this.signatureStatus,
    this.createdAt,
  });

  factory QrPrescription.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> sub(String key) {
      final v = json[key];
      return v is Map<String, dynamic> ? v : const {};
    }

    final prescriber = sub('prescriber');
    final patient = sub('patient');
    final signature = sub('signature');
    final rawMedicines = json['medicines'];

    return QrPrescription(
      number: _str(json['prescriptionNumber']) ?? '',
      prescriberName: _str(prescriber['name']),
      prescriberHpcsa: _str(prescriber['hpcsa']),
      prescriberPhone: _str(prescriber['phone']),
      patientName: _str(patient['name']),
      diagnosis: _str(json['diagnosis']),
      clinicalNotes: _str(json['clinicalNotes']),
      signatureStatus: _str(signature['status']),
      signedAt: DateTime.tryParse(_str(signature['timestamp']) ?? ''),
      createdAt: DateTime.tryParse(_str(json['createdAt']) ?? ''),
      medicines: rawMedicines is List
          ? rawMedicines
              .whereType<Map<String, dynamic>>()
              .map(QrMedicine.fromJson)
              .toList()
          : const [],
    );
  }

  final String number;
  final String? prescriberName;
  final String? prescriberHpcsa;
  final String? prescriberPhone;
  final String? patientName;
  final String? diagnosis;
  final String? clinicalNotes;
  final String? signatureStatus;
  final DateTime? signedAt;
  final DateTime? createdAt;
  final List<QrMedicine> medicines;

  bool get isSigned => signatureStatus == 'signed';

  @override
  List<Object?> get props => [number, medicines, signedAt];

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// One medicine on a QR-opened prescription.
class QrMedicine extends Equatable {
  const QrMedicine({
    required this.name,
    this.dosage,
    this.form,
    this.quantity,
    this.frequency,
    this.route,
    this.duration,
    this.instructions,
    this.schedule,
  });

  factory QrMedicine.fromJson(Map<String, dynamic> json) {
    return QrMedicine(
      name: QrPrescription._str(json['name']) ?? 'Unnamed medicine',
      dosage: QrPrescription._str(json['dosage']),
      form: QrPrescription._str(json['form']),
      quantity: json['quantity']?.toString(),
      frequency: QrPrescription._str(json['frequency']),
      route: QrPrescription._str(json['route']),
      duration: QrPrescription._str(json['duration']),
      instructions: QrPrescription._str(json['instructions']),
      schedule: QrPrescription._str(json['schedule']),
    );
  }

  final String name;
  final String? dosage;
  final String? form;
  final String? quantity;
  final String? frequency;
  final String? route;
  final String? duration;
  final String? instructions;
  final String? schedule;

  /// "500mg tablet · 20 · four times daily · oral"
  String get detail => [
        [dosage, form].whereType<String>().join(' '),
        quantity,
        frequency,
        route,
        duration,
      ].where((p) => p != null && p.isNotEmpty).join(' · ');

  @override
  List<Object?> get props => [name, dosage, quantity, frequency];
}

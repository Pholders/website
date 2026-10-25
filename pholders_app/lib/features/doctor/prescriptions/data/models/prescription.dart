import 'package:equatable/equatable.dart';

/// Where a prescription is in its lifecycle.
///
/// The backend tracks this as `signature_status`, which only ever holds
/// 'pending' or 'signed' — a prescription is not legally valid until the
/// doctor signs it.
enum PrescriptionStatus { pending, signed, revoked, unknown }

/// A prescription issued by the signed-in doctor.
///
/// Shape comes from `GET /prescriptions/doctor/all`, which returns a mapped
/// summary rather than the raw row: it carries no medicines, so the medicine
/// list is only available on the per-prescription endpoints.
class Prescription extends Equatable {
  const Prescription({
    required this.id,
    required this.number,
    required this.patientName,
    this.diagnosis,
    this.status = PrescriptionStatus.unknown,
    this.createdAt,
    this.patientId,
    this.appointmentId,
    this.revokeReason,
    this.isDispensed = false,
    this.dispensedAt,
    this.dispensedByPharmacyName,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: _asInt(json['id']) ?? 0,
      number: _asString(json['prescriptionNumber']) ?? '',
      patientName: _asString(json['patient']) ?? 'Unknown patient',
      diagnosis: _asString(json['diagnosis']),
      status: _statusFrom(_asString(json['status'])),
      createdAt: DateTime.tryParse(_asString(json['createdAt']) ?? ''),
      patientId: _asInt(json['patientId']),
      appointmentId: _asInt(json['appointmentId']),
      revokeReason: _asString(json['revokeReason']),
      isDispensed: json['isDispensed'] == true,
      dispensedAt: DateTime.tryParse(_asString(json['dispensedAt']) ?? ''),
      dispensedByPharmacyName: _asString(json['dispensedByPharmacyName']),
    );
  }

  final int id;

  /// Human-facing reference, e.g. "RX-2026-04821".
  final String number;
  final String patientName;
  final String? diagnosis;
  final PrescriptionStatus status;
  final DateTime? createdAt;

  /// Lets the app open the patient a script was written for. Null on older
  /// responses — the field was added to the doctor list in Oct 2026.
  final int? patientId;
  final int? appointmentId;

  /// Why the doctor withdrew it. A revoke cannot happen without one.
  final String? revokeReason;

  /// Dispensing is the pharmacy's act, not the doctor's; these are shown and
  /// never set from here.
  final bool isDispensed;
  final DateTime? dispensedAt;
  final String? dispensedByPharmacyName;

  /// True once signed, which is when it becomes dispensable.
  bool get isSigned => status == PrescriptionStatus.signed;

  /// A short line for the dispensing detail, or null when it has not been
  /// dispensed.
  String? get dispensedSummary {
    if (!isDispensed) return null;
    final pharmacy = dispensedByPharmacyName;
    final when = dispensedAt;
    if (pharmacy != null && when != null) {
      return 'Dispensed by $pharmacy on ${_shortDate(when)}';
    }
    if (pharmacy != null) return 'Dispensed by $pharmacy';
    if (when != null) return 'Dispensed on ${_shortDate(when)}';
    return 'Dispensed';
  }

  /// Label for the status chip.
  String get statusLabel {
    switch (status) {
      case PrescriptionStatus.pending:
        return 'Awaiting signature';
      case PrescriptionStatus.signed:
        return 'Signed';
      case PrescriptionStatus.revoked:
        return 'Revoked';
      case PrescriptionStatus.unknown:
        return 'Unknown';
    }
  }

  /// "01 Mar", matching the column format in the prescriptions table.
  String get formattedDate => createdAt == null ? '' : _shortDate(createdAt!);

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]}';
  }

  static PrescriptionStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'pending':
        return PrescriptionStatus.pending;
      case 'signed':
        return PrescriptionStatus.signed;
      case 'revoked':
        return PrescriptionStatus.revoked;
      default:
        return PrescriptionStatus.unknown;
    }
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [
        id, number, patientName, diagnosis, status, createdAt,
        patientId, appointmentId, revokeReason,
        isDispensed, dispensedAt, dispensedByPharmacyName,
      ];
}

import 'package:equatable/equatable.dart';

/// What the backend hands back when a prescription is signed.
///
/// This is the only time the doctor ever sees the QR payload and access link:
/// the token is generated during signing and no doctor-callable endpoint
/// returns it afterwards. Signing again is rejected, so if this is lost it
/// cannot be recovered — which is why the dialog says so.
class SigningReceipt extends Equatable {
  const SigningReceipt({
    required this.prescriptionId,
    required this.prescriptionNumber,
    required this.qrPayload,
    required this.accessLink,
    this.signedAt,
    this.signatureMethod,
    this.signatureFingerprint,
    this.medicineCount,
    this.signedBy,
  });

  factory SigningReceipt.fromJson(Map<String, dynamic> json) {
    final audit = json['auditTrail'];
    final auditMap = audit is Map ? Map<String, dynamic>.from(audit) : const {};

    return SigningReceipt(
      prescriptionId: _asInt(json['prescriptionId']) ?? 0,
      prescriptionNumber: json['prescriptionNumber']?.toString() ?? '',
      qrPayload: json['qrCode']?.toString() ?? '',
      accessLink: json['accessLink']?.toString() ?? '',
      signedAt: DateTime.tryParse(json['signatureTimestamp']?.toString() ?? ''),
      signatureMethod: json['signatureMethod']?.toString(),
      signatureFingerprint: json['signatureFingerprint']?.toString(),
      medicineCount: _asInt(json['medicineCount']),
      signedBy: auditMap['signedBy']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  final int prescriptionId;
  final String prescriptionNumber;

  /// The string a pharmacy scanner reads, in the backend's own format:
  /// `PRESCRIPTION|<id>|<token>|<timestamp>`.
  final String qrPayload;

  /// The secure link to the same prescription, for emailing to the patient.
  final String accessLink;

  final DateTime? signedAt;
  final String? signatureMethod;
  final String? signatureFingerprint;
  final int? medicineCount;
  final String? signedBy;

  /// False when the server gave us nothing to show — then the dialog is
  /// pointless and the caller should stay quiet rather than open an empty one.
  bool get hasCode => qrPayload.isNotEmpty || accessLink.isNotEmpty;

  /// The deployed server builds this from `FRONTEND_URL`, which is unset, so
  /// it falls back to a localhost address that resolves nowhere. Worth warning
  /// about rather than handing the patient a dead link.
  bool get linkIsUnreachable =>
      accessLink.contains('localhost') || accessLink.contains('127.0.0.1');

  @override
  List<Object?> get props => [
        prescriptionId,
        prescriptionNumber,
        qrPayload,
        accessLink,
        signedAt,
        signatureMethod,
        signatureFingerprint,
        medicineCount,
        signedBy,
      ];
}

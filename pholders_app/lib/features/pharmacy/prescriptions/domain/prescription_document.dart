/// Industry-standard prescription document model aligned with Pholders SRS
/// (FR-G-010, FR-G-055) and SA e-prescribing practice (HPCSA, NAPPI, Schedules).
class PrescriptionDocument {

  const PrescriptionDocument({
    required this.referenceNumber,
    required this.prescriptionId,
    required this.prescriber,
    required this.patient,
    required this.medicalAid,
    this.diagnosis,
    required this.medications,
    this.additionalSelfMedication = const [],
    required this.genericSubstitution,
    required this.collection,
    required this.payment,
    required this.signature,
    required this.currentStatus,
    required this.issuedDate,
    required this.validUntilDate,
  });
  final String referenceNumber;
  final String prescriptionId;
  final PrescriberInfo prescriber;
  final PatientInfo patient;
  final MedicalAidInfo medicalAid;
  final DiagnosisInfo? diagnosis;
  final List<PrescriptionMedication> medications;
  final List<String> additionalSelfMedication;
  final String genericSubstitution;
  final CollectionInfo collection;
  final PaymentInfo payment;
  final DigitalSignatureInfo signature;
  final String currentStatus;
  final DateTime issuedDate;
  final DateTime validUntilDate;

  /// Compact payload encoded in the document QR code for pharmacy scan/claim.
  String get qrPayload =>
      'PHOLDERS|RX|$referenceNumber|${prescriber.hpcsaNumber}|${patient.idNumber}';

  String get issuedDateFormatted => _formatDate(issuedDate);

  String get validUntilFormatted => _formatDate(validUntilDate);

  static String _formatDate(DateTime date) {
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
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class PrescriberInfo {

  const PrescriberInfo({
    required this.name,
    required this.qualification,
    required this.hpcsaNumber,
    required this.practiceNumber,
    required this.practiceName,
    required this.practiceAddress,
    required this.contactNumber,
  });
  final String name;
  final String qualification;
  final String hpcsaNumber;
  final String practiceNumber;
  final String practiceName;
  final String practiceAddress;
  final String contactNumber;
}

class PatientInfo {

  const PatientInfo({
    required this.name,
    required this.idNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.phone,
    required this.email,
  });
  final String name;
  final String idNumber;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String phone;
  final String email;
}

class MedicalAidInfo {

  const MedicalAidInfo({
    required this.schemeName,
    required this.plan,
    required this.memberNumber,
    required this.dependentCode,
    required this.dependentDescription,
    this.authorizationNumber = 'Not required',
  });
  final String schemeName;
  final String plan;
  final String memberNumber;
  final String dependentCode;
  final String dependentDescription;
  final String authorizationNumber;
}

class DiagnosisInfo {

  const DiagnosisInfo({
    required this.icd10Code,
    required this.description,
  });
  final String icd10Code;
  final String description;

  String get display => '$icd10Code — $description';
}

class PrescriptionMedication {

  const PrescriptionMedication({
    required this.lineNumber,
    required this.name,
    required this.strength,
    required this.nappiCode,
    required this.schedule,
    required this.dosage,
    required this.route,
    required this.frequency,
    required this.duration,
    required this.quantityNumber,
    required this.quantityWords,
    this.repeats = 0,
    this.instructions = const [],
  });
  final int lineNumber;
  final String name;
  final String strength;
  final String nappiCode;
  final String schedule;
  final String dosage;
  final String route;
  final String frequency;
  final String duration;
  final int quantityNumber;
  final String quantityWords;
  final int repeats;
  final List<String> instructions;

  String get fullName => strength.isEmpty ? name : '$name $strength';

  String get quantityDisplay => '$quantityWords ($quantityNumber)';
}

class CollectionInfo {

  const CollectionInfo({
    required this.preference,
    required this.pharmacyName,
    this.pharmacyAddress = '',
  });
  final String preference;
  final String pharmacyName;
  final String pharmacyAddress;
}

class PaymentInfo {

  const PaymentInfo({
    required this.method,
    required this.status,
  });
  final String method;
  final String status;
}

class DigitalSignatureInfo {

  const DigitalSignatureInfo({
    required this.signedBy,
    required this.hpcsaNumber,
    required this.verificationMethod,
    required this.verifiedStatus,
    required this.signedAt,
  });
  final String signedBy;
  final String hpcsaNumber;
  final String verificationMethod;
  final String verifiedStatus;
  final DateTime signedAt;

  String get signedAtFormatted {
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
      'Dec',
    ];
    final date = signedAt;
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} $hh:$mm SAST';
  }
}

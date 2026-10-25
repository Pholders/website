import '../domain/prescription_document.dart';

/// Mock prescription data for UI-only Phase 1 flows.
PrescriptionDocument samplePrescriptionDocument({
  required String prescriptionId,
  String currentStatus = 'New',
}) {
  return PrescriptionDocument(
    referenceNumber: 'PH-RX-2026-${prescriptionId.padLeft(6, '0')}',
    prescriptionId: prescriptionId,
    prescriber: const PrescriberInfo(
      name: 'Dr Sam Smith',
      qualification: 'MBChB (Wits)',
      hpcsaNumber: 'MP12345678',
      practiceNumber: '0865432',
      practiceName: 'Mashumu Medical Practice',
      practiceAddress: '123 Rivonia Road, Sandton, Johannesburg, 2196',
      contactNumber: '+27 11 555 0100',
    ),
    patient: const PatientInfo(
      name: 'Maria Wilson',
      idNumber: '9803015800088',
      dateOfBirth: '01 Mar 1998',
      gender: 'Female',
      address: '45 Main Street, Rosebank, Johannesburg, 2196',
      phone: '+27 82 555 1234',
      email: 'maria.wilson@email.com',
    ),
    medicalAid: const MedicalAidInfo(
      schemeName: 'Discovery Health',
      plan: 'KeyCare Plus',
      memberNumber: 'DH-90012345',
      dependentCode: '00',
      dependentDescription: 'Principal Member',
    ),
    diagnosis: const DiagnosisInfo(
      icd10Code: 'J06.9',
      description: 'Acute upper respiratory infection, unspecified',
    ),
    medications: const [
      PrescriptionMedication(
        lineNumber: 1,
        name: 'Panado',
        strength: '500 mg Tablets',
        nappiCode: '703684001',
        schedule: 'S2',
        dosage: '1 tablet',
        route: 'Oral',
        frequency: 'Twice daily after meals',
        duration: '5 days',
        quantityNumber: 10,
        quantityWords: 'TEN',
        repeats: 0,
        instructions: ['Take after meals', 'Do not exceed 8 tablets in 24 hours'],
      ),
      PrescriptionMedication(
        lineNumber: 2,
        name: 'Amoxicillin',
        strength: '500 mg Capsules',
        nappiCode: '824215001',
        schedule: 'S4',
        dosage: '1 capsule',
        route: 'Oral',
        frequency: 'Three times daily',
        duration: '7 days',
        quantityNumber: 21,
        quantityWords: 'TWENTY-ONE',
        repeats: 0,
        instructions: ['Complete the full course', 'Take with water'],
      ),
    ],
    additionalSelfMedication: const [
      'Vitamin C 1000 mg — 1 tablet daily (patient reported)',
    ],
    genericSubstitution: 'Allowed on all products',
    collection: const CollectionInfo(
      preference: 'In-Store Collection',
      pharmacyName: 'Pholders Pharmacy — Sandton',
      pharmacyAddress: 'Shop 12, Sandton City, Sandton, 2196',
    ),
    payment: const PaymentInfo(
      method: 'Medical Aid',
      status: 'Covered — R0.00 co-payment',
    ),
    signature: DigitalSignatureInfo(
      signedBy: 'Dr Sam Smith',
      hpcsaNumber: 'MP12345678',
      verificationMethod: 'OTP-verified Advanced Electronic Signature',
      verifiedStatus: 'Verified',
      signedAt: DateTime(2026, 3, 25, 14, 32),
    ),
    currentStatus: currentStatus,
    issuedDate: DateTime(2026, 3, 25),
    validUntilDate: DateTime(2026, 6, 25),
  );
}

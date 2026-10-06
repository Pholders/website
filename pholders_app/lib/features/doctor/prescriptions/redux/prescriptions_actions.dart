import '../data/models/medicine_draft.dart';
import '../data/models/prescription.dart';
import '../data/models/safety_report.dart';
import '../data/models/signing_receipt.dart';

/// Dispatched when the prescriptions list is opened or refreshed.
class LoadPrescriptionsAction {
  const LoadPrescriptionsAction({this.filter = 'all'});

  /// 'all', 'signed' or 'pending'.
  final String filter;
}

/// Dispatched by the middleware when the list arrives.
class PrescriptionsLoadedAction {
  const PrescriptionsLoadedAction({required this.prescriptions});
  final List<Prescription> prescriptions;
}

/// Dispatched by the middleware when the list fails to load.
class PrescriptionsLoadFailedAction {
  const PrescriptionsLoadFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the doctor signs a prescription.
class SignPrescriptionAction {
  const SignPrescriptionAction({required this.prescriptionId});
  final int prescriptionId;
}

/// Dispatched when the doctor revokes a prescription.
///
/// [reason] is mandatory: the backend rejects a revoke without one, and it is
/// what the audit trail records in place of a deletion.
class RevokePrescriptionAction {
  const RevokePrescriptionAction({
    required this.prescriptionId,
    required this.reason,
  });
  final int prescriptionId;
  final String reason;
}

/// Dispatched once a prescription is signed, carrying the QR payload and
/// access link so the UI can show them.
///
/// This is the only chance to show them: the token is minted during signing
/// and no doctor endpoint returns it afterwards.
class PrescriptionSignedAction {
  const PrescriptionSignedAction({required this.receipt});
  final SigningReceipt receipt;
}

/// Dismisses the signing receipt so it cannot reappear on the next sign.
class ClearSigningReceiptAction {
  const ClearSigningReceiptAction();
}

/// Dispatched when a sign or revoke call fails.
class PrescriptionActionFailedAction {
  const PrescriptionActionFailedAction({
    required this.prescriptionId,
    required this.errorMessage,
  });
  final int prescriptionId;
  final String errorMessage;
}

/// Dispatched when the doctor submits the new-prescription form.
///
/// The backend needs three calls for this — create, then one per medicine —
/// so the middleware sequences them.
class CreatePrescriptionAction {
  const CreatePrescriptionAction({
    required this.appointmentId,
    required this.diagnosis,
    required this.medicines,
    this.clinicalNotes,
  });

  final int appointmentId;
  final String diagnosis;
  final List<MedicineDraft> medicines;
  final String? clinicalNotes;
}

/// Dispatched once a prescription and all its medicines are saved.
class PrescriptionCreatedAction {
  const PrescriptionCreatedAction({required this.prescriptionId});
  final int prescriptionId;
}

/// Dispatched when creating a prescription fails.
class CreatePrescriptionFailedAction {
  const CreatePrescriptionFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the doctor asks for a drug interaction check.
class CheckInteractionsAction {
  const CheckInteractionsAction({required this.prescriptionId});
  final int prescriptionId;
}

/// Dispatched when the safety report comes back.
class InteractionsCheckedAction {
  const InteractionsCheckedAction({
    required this.prescriptionId,
    required this.report,
  });
  final int prescriptionId;
  final SafetyReport report;
}

/// Dispatched when the check could not be run.
class InteractionsCheckFailedAction {
  const InteractionsCheckFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the report is dismissed, so a stale one is not shown next
/// time the dialog opens.
class ClearInteractionsReportAction {
  const ClearInteractionsReportAction();
}

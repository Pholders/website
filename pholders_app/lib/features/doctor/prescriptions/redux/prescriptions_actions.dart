import '../data/models/prescription.dart';

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
class RevokePrescriptionAction {
  const RevokePrescriptionAction({required this.prescriptionId, this.reason});
  final int prescriptionId;
  final String? reason;
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

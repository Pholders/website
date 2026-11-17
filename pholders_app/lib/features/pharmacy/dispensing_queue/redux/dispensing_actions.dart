import '../data/models/claimed_prescription.dart';

/// Dispatched when the dispensing queue opens or is refreshed.
class LoadDispensingQueueAction {
  const LoadDispensingQueueAction();
}

/// Dispatched when both lists arrive.
class DispensingQueueLoadedAction {
  const DispensingQueueLoadedAction({
    required this.awaiting,
    required this.dispensed,
  });

  final List<ClaimedPrescription> awaiting;
  final List<ClaimedPrescription> dispensed;
}

/// Dispatched when the queue cannot be loaded.
class DispensingQueueFailedAction {
  const DispensingQueueFailedAction({required this.errorMessage});
  final String errorMessage;
}

/// Dispatched when the pharmacy hands the medicine over.
class DispensePrescriptionAction {
  const DispensePrescriptionAction({required this.prescriptionId, this.notes});
  final int prescriptionId;
  final String? notes;
}

/// Dispatched when a dispense fails, so the row can say why.
class DispenseFailedAction {
  const DispenseFailedAction({
    required this.prescriptionId,
    required this.errorMessage,
  });
  final int prescriptionId;
  final String errorMessage;
}

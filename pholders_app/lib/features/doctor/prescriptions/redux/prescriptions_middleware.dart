import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/models/prescription.dart';
import '../data/prescriptions_repository.dart';
import 'prescriptions_actions.dart';

/// Middleware performing the prescription network calls.
List<Middleware<AppState>> createPrescriptionsMiddleware({
  required PrescriptionsRepository repository,
}) {
  Future<void> load(Store<AppState> store, String filter) async {
    try {
      final prescriptions = await repository.fetchAll(filter: filter);
      store.dispatch(PrescriptionsLoadedAction(prescriptions: prescriptions));
    } on ApiException catch (e) {
      store.dispatch(PrescriptionsLoadFailedAction(errorMessage: e.message));
    }
  }

  /// The prescription as the server now holds it, after a refetch.
  Prescription? find(Store<AppState> store, int id) {
    for (final p in store.state.prescriptionsState.prescriptions) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> create(
    Store<AppState> store,
    CreatePrescriptionAction action,
  ) async {
    int? id;
    var saved = 0;
    try {
      id = await repository.create(
        appointmentId: action.appointmentId,
        diagnosis: action.diagnosis,
        clinicalNotes: action.clinicalNotes,
      );

      // Medicines are separate rows added after the prescription exists, and
      // an unsigned prescription with no medicines cannot be signed, so a
      // failure part-way still leaves a usable draft to finish or revoke.
      for (final m in action.medicines) {
        await repository.addMedicine(
          prescriptionId: id,
          medicineName: m.name,
          dosage: m.dosage,
          dosageForm: m.form,
          quantity: m.quantity,
          frequency: m.frequency,
          routeOfAdministration: m.route,
          duration: m.duration,
          specialInstructions: m.instructions,
        );
        saved++;
      }

      store.dispatch(PrescriptionCreatedAction(prescriptionId: id));
      await load(store, 'all');
      action.result?.complete(id);
    } on ApiException catch (e) {
      store.dispatch(CreatePrescriptionFailedAction(errorMessage: e.message));
      if (id == null) {
        action.result?.completeError(e);
        return;
      }
      // The draft exists even though a medicine failed, so show it in the
      // list and tell the form, which must not resubmit.
      await load(store, 'all');
      action.result?.completeError(PartialPrescriptionException(
        prescriptionId: id,
        saved: saved,
        total: action.medicines.length,
        failedMedicine: action.medicines[saved].name,
        cause: e,
      ));
    }
  }

  Future<void> checkInteractions(
    Store<AppState> store,
    CheckInteractionsAction action,
  ) async {
    try {
      final report = await repository.checkInteractions(action.prescriptionId);
      store.dispatch(InteractionsCheckedAction(
        prescriptionId: action.prescriptionId,
        report: report,
      ));
    } on ApiException catch (e) {
      store.dispatch(InteractionsCheckFailedAction(errorMessage: e.message));
    }
  }

  Future<void> sign(Store<AppState> store, SignPrescriptionAction action) async {
    try {
      final receipt = await repository.sign(action.prescriptionId);
      // The QR and link exist only in this response, so hand them to the UI
      // before anything else can overwrite the slice.
      if (receipt.hasCode) {
        store.dispatch(PrescriptionSignedAction(receipt: receipt));
      }
      // Signing changes the status, so refetch rather than guessing.
      await load(store, 'all');
      action.result?.complete(RxActionOutcome(
        number: find(store, action.prescriptionId)?.number,
        hasReceipt: receipt.hasCode,
      ));
    } on ApiException catch (e) {
      store.dispatch(PrescriptionActionFailedAction(
        prescriptionId: action.prescriptionId,
        errorMessage: e.message,
      ));
      // The backend can apply the change and then fail while sending its
      // notification email, returning 500 for work it actually did. Refetch
      // so the list shows what the server really holds, not what the error
      // implies.
      await load(store, 'all');
      final now = find(store, action.prescriptionId);
      if (now != null && now.isSigned) {
        action.result?.complete(
            RxActionOutcome(number: now.number, serverErrorAfterSave: true));
      } else {
        action.result?.completeError(e);
      }
    }
  }

  Future<void> revoke(
    Store<AppState> store,
    RevokePrescriptionAction action,
  ) async {
    try {
      await repository.revoke(action.prescriptionId, reason: action.reason);
      await load(store, 'all');
      action.result?.complete(
          RxActionOutcome(number: find(store, action.prescriptionId)?.number));
    } on ApiException catch (e) {
      store.dispatch(PrescriptionActionFailedAction(
        prescriptionId: action.prescriptionId,
        errorMessage: e.message,
      ));
      // Same as signing: revoke currently persists and then 500s on its
      // notification email, so the error alone cannot be trusted.
      await load(store, 'all');
      final now = find(store, action.prescriptionId);
      final revoked = now != null &&
          (now.status == PrescriptionStatus.revoked || now.revokeReason != null);
      if (revoked) {
        action.result?.complete(
            RxActionOutcome(number: now.number, serverErrorAfterSave: true));
      } else {
        action.result?.completeError(e);
      }
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);

    if (action is LoadPrescriptionsAction) {
      load(store, action.filter);
    } else if (action is CreatePrescriptionAction) {
      create(store, action);
    } else if (action is CheckInteractionsAction) {
      checkInteractions(store, action);
    } else if (action is SignPrescriptionAction) {
      sign(store, action);
    } else if (action is RevokePrescriptionAction) {
      revoke(store, action);
    }
  }

  return [middleware];
}

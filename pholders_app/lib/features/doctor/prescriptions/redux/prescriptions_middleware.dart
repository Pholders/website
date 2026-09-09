import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
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

  Future<void> create(
    Store<AppState> store,
    CreatePrescriptionAction action,
  ) async {
    try {
      final id = await repository.create(
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
      }

      store.dispatch(PrescriptionCreatedAction(prescriptionId: id));
      await load(store, 'all');
    } on ApiException catch (e) {
      store.dispatch(CreatePrescriptionFailedAction(errorMessage: e.message));
    }
  }

  Future<void> sign(Store<AppState> store, SignPrescriptionAction action) async {
    try {
      await repository.sign(action.prescriptionId);
      // Signing changes the status, so refetch rather than guessing.
      await load(store, 'all');
    } on ApiException catch (e) {
      store.dispatch(PrescriptionActionFailedAction(
        prescriptionId: action.prescriptionId,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> revoke(
    Store<AppState> store,
    RevokePrescriptionAction action,
  ) async {
    try {
      await repository.revoke(action.prescriptionId, reason: action.reason);
      await load(store, 'all');
    } on ApiException catch (e) {
      store.dispatch(PrescriptionActionFailedAction(
        prescriptionId: action.prescriptionId,
        errorMessage: e.message,
      ));
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);

    if (action is LoadPrescriptionsAction) {
      load(store, action.filter);
    } else if (action is CreatePrescriptionAction) {
      create(store, action);
    } else if (action is SignPrescriptionAction) {
      sign(store, action);
    } else if (action is RevokePrescriptionAction) {
      revoke(store, action);
    }
  }

  return [middleware];
}

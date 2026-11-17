import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../../prescriptions/redux/prescriptions_actions.dart';
import '../data/patient_record_repository.dart';

/// Loads every patient's record, and the doctor's prescriptions, in the
/// background once the doctor's appointments are in, which is as soon as
/// they sign in, so a profile opens on data already fetched. Each record is fetched once a session (see
/// [PatientRecordRepository]); later reloads of the appointments only fetch
/// patients who are new. Signing out forgets them all.
List<Middleware<AppState>> createPatientRecordsMiddleware({
  required PatientRecordRepository repository,
}) {
  /// Patients a few at a time, so the first profile opened is not queued
  /// behind every other patient's requests.
  ///
  /// Stops if the doctor signs out meanwhile: the rest would go without a
  /// session, and their refusals would read as one that had expired.
  Future<void> prefetchAll(List<String> ids) async {
    const batch = 3;
    final session = repository.generation;
    for (var i = 0; i < ids.length; i += batch) {
      if (repository.generation != session) return;
      final end = i + batch > ids.length ? ids.length : i + batch;
      await Future.wait(ids.sublist(i, end).map(repository.prefetch));
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    if (action is LogoutAction || action is SessionExpiredAction) {
      repository.clear();
    }
    next(action);
    if (action is AppointmentsLoadedAction && store.state.authState.isDoctor) {
      // The doctor's prescriptions too, once, so the Prescriptions page and
      // each patient's Prescriptions tab open on them.
      final rx = store.state.prescriptionsState;
      if (!rx.hasLoadedOnce && !rx.isLoading) {
        store.dispatch(const LoadPrescriptionsAction());
      }

      final ids = <String>{
        for (final a in action.appointments)
          if (a.patientId != null) '${a.patientId}',
      }.where((id) => !repository.hasFetched(id)).toList();
      if (ids.isNotEmpty) prefetchAll(ids);
    }
  }

  return [middleware];
}

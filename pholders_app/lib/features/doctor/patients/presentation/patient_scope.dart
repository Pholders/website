import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../data/doctor_patient.dart';
import 'patients_screen.dart';

/// Resolves the patient named in the URL against the doctor's own list.
///
/// Each of the patient pages used to construct the same invented record and
/// ignore the id in the address entirely, so opening any patient showed one
/// particular stranger's name, condition and history. Deep links are a
/// documented way in, which made that reachable in ordinary use.
///
/// The list a doctor has is built from their own appointments, so an id they
/// have never had a booking with is genuinely not theirs to see: it reports
/// not found rather than inventing someone.
class PatientScope extends StatelessWidget {
  const PatientScope({
    super.key,
    required this.patientId,
    required this.builder,
  });

  final String patientId;
  final Widget Function(BuildContext context, Patient patient) builder;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _PatientScopeViewModel>(
      onInit: (store) => store.dispatch(const LoadAppointmentsAction()),
      converter: (store) => _PatientScopeViewModel.fromStore(store, patientId),
      builder: (context, vm) {
        final found = vm.patient;
        if (found != null) {
          return builder(context, Patient.fromDoctorPatient(found));
        }

        // Still arriving. Appointments are what the list is derived from, so
        // until they have landed once, absence means nothing either way.
        if (vm.isLoading || !vm.hasLoaded) {
          return const PatientPageNotice(
            icon: Icons.hourglass_empty_rounded,
            title: 'Loading the patient…',
          );
        }

        if (vm.errorMessage != null) {
          return PatientPageNotice(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your patients',
            detail: vm.errorMessage,
          );
        }

        return const PatientPageNotice(
          icon: Icons.person_off_outlined,
          title: 'Patient not found',
          detail: 'Your patient list is built from your own bookings, so a '
              'patient appears here only once they have booked with you.',
        );
      },
    );
  }
}

class _PatientScopeViewModel {
  const _PatientScopeViewModel({
    required this.patient,
    required this.isLoading,
    required this.hasLoaded,
    required this.errorMessage,
  });

  factory _PatientScopeViewModel.fromStore(
    Store<AppState> store,
    String patientId,
  ) {
    final state = store.state.appointmentsState;
    final wanted = int.tryParse(patientId);
    final patients = patientsFromAppointments(state.appointments);

    DoctorPatient? match;
    if (wanted != null) {
      for (final candidate in patients) {
        if (candidate.id == wanted) {
          match = candidate;
          break;
        }
      }
    }

    return _PatientScopeViewModel(
      patient: match,
      isLoading: state.isLoading,
      hasLoaded: state.hasLoadedOnce,
      errorMessage: state.errorMessage,
    );
  }

  final DoctorPatient? patient;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
}

/// A centred notice standing in for a patient page's content: loading, not
/// found, or a page this phase does not build.
class PatientPageNotice extends StatelessWidget {
  const PatientPageNotice({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.teal),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

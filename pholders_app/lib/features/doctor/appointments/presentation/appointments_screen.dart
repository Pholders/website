import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;

const _teal = Color(0xFF2EC4C4);
const _tealLight = Color(0xFFE6F7F7);
const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);

/// The Appointments tab of a patient's profile: their visits with this
/// doctor, taken from the doctor's own appointments.
///
/// It used to show three invented visits ("Treatment of diabetes" with
/// "Dr Sam Smith" on 26 Apr 2026) under whichever real patient was open, with
/// fixed counts and a calendar stuck on 15 April.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.patient});
  final Patient patient;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _tab = 0; // 0 upcoming, 1 past

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _VisitsViewModel>(
      distinct: true,
      onInit: (store) {
        if (!store.state.appointmentsState.hasLoadedOnce) {
          store.dispatch(const LoadAppointmentsAction());
        }
      },
      converter: (store) => _VisitsViewModel.of(store.state, widget.patient.id),
      builder: (context, vm) => Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _tabButton(0, 'Upcoming (${vm.upcoming.length})'),
                  _tabButton(1, 'Past (${vm.past.length})'),
                ],
              ),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 12),
              _body(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final active = index == _tab;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: active ? _teal : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? _teal : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _body(_VisitsViewModel vm) {
    if (vm.loading && !vm.loaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
          ),
        ),
      );
    }
    if (vm.error != null && !vm.loaded) {
      return _message(vm.error!);
    }
    final visits = _tab == 0 ? vm.upcoming : vm.past;
    if (visits.isEmpty) {
      return _message(_tab == 0
          ? 'No upcoming visits with you.'
          : 'No past visits with you yet.');
    }
    return Column(
      children: [for (final a in visits) _VisitRow(appointment: a)],
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: _textSecondary)),
      );
}

class _VisitsViewModel {
  const _VisitsViewModel({
    required this.upcoming,
    required this.past,
    required this.loading,
    required this.loaded,
    this.error,
  });

  /// Only this patient's visits, split the way the Appointments page splits
  /// them: past = completed or an earlier day.
  factory _VisitsViewModel.of(AppState state, String patientId) {
    final s = state.appointmentsState;
    final now = DateTime.now();
    final mine =
        s.appointments.where((a) => '${a.patientId}' == patientId).toList();
    final far = DateTime(9999);
    int byDate(Appointment a, Appointment b) {
      final c = (a.date ?? far).compareTo(b.date ?? far);
      return c != 0 ? c : (a.timeSlot ?? '').compareTo(b.timeSlot ?? '');
    }

    final upcoming = mine.where((a) => !a.isPastAt(now)).toList()
      ..sort(byDate);
    final past = mine.where((a) => a.isPastAt(now)).toList()
      ..sort((a, b) => byDate(b, a));
    return _VisitsViewModel(
      upcoming: upcoming,
      past: past,
      loading: s.isLoading,
      loaded: s.hasLoadedOnce,
      error: s.errorMessage,
    );
  }

  final List<Appointment> upcoming;
  final List<Appointment> past;
  final bool loading;
  final bool loaded;
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is _VisitsViewModel &&
      _same(other.upcoming, upcoming) &&
      _same(other.past, past) &&
      other.loading == loading &&
      other.loaded == loaded &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(upcoming.length, past.length, loading, loaded, error);

  static bool _same(List<Appointment> a, List<Appointment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.formattedDate,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                const SizedBox(height: 2),
                Text(a.timeRange,
                    style:
                        const TextStyle(fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(a.reason ?? 'Consultation',
                style: const TextStyle(fontSize: 13, color: _textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(a.statusLabel,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _teal)),
          ),
        ],
      ),
    );
  }
}

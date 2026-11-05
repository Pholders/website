import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/doctor_search_scope.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../../dashboard/data/dashboard_summary.dart' as summary;
import '../data/doctor_patient.dart';
import 'patient_table.dart';

// ─── Colours ─────────────────────────────────────────────────────────────────
class AppColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const tealDark = Color(0xFF1A9E9E);
  static const amber = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFF3DC);
  static const stableGreen = Color(0xFF2EC4C4);
  static const stableBg = Color(0xFFD9F3F3);
  static const monitoredOrange = Color(0xFFF5A623);
  static const monitoredBg = Color(0xFFFFF0CE);
  static const sidebar = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4FAFA);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const alertBg = Color(0xFFFFF8E8);
  static const alertBorder = Color(0xFFF5A623);
  static const addButton = Color(0xFFF5A623);
}

// ─── Data model ──────────────────────────────────────────────────────────────
// Kept because several other screens still type against these. Nothing on
// this page uses them any more: the list is built from DoctorPatient, which
// carries only what the appointments actually say.
enum PatientStatus { stable, monitored, critical }

enum PatientCategory { outpatient, remoteCare, followUp }

class Patient {
  Patient({
    required this.id,
    required this.name,
    required this.condition,
    required this.lastActivity,
    required this.status,
    required this.priority,
    required this.category,
    this.avatarInitials,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  /// Built from a real patient, so the older detail screens can keep their
  /// type while showing what the appointments actually say.
  factory Patient.fromDoctorPatient(DoctorPatient p) => Patient(
        id: '${p.id}',
        name: p.name,
        condition: p.lastReason ?? 'No reason recorded',
        lastActivity: p.lastSeen == null
            ? 'No visit recorded'
            : formatPatientDate(p.lastSeen),
        // Nothing in the data supports a clinical judgement, so none is made.
        status: PatientStatus.stable,
        priority: 'Not set',
        category: PatientCategory.outpatient,
        avatarInitials: p.initials,
        email: p.email,
        phone: p.phone,
        avatarUrl: p.avatarUrl,
      );

  final String id;
  String name;
  String condition;
  String lastActivity;
  PatientStatus status;
  String priority;
  PatientCategory category;
  String? avatarInitials;

  /// Real contact details when they came from a booking; null otherwise.
  String? email;
  String? phone;

  /// Their profile photo, or null when they have not set one.
  String? avatarUrl;

  Patient copyWith({
    String? name,
    String? condition,
    String? lastActivity,
    PatientStatus? status,
    String? priority,
    PatientCategory? category,
  }) =>
      Patient(
        id: id,
        name: name ?? this.name,
        condition: condition ?? this.condition,
        lastActivity: lastActivity ?? this.lastActivity,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        avatarInitials: avatarInitials,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );
}

// ─── Patients screen ─────────────────────────────────────────────────────────
/// Everyone who has booked this doctor, laid out to the Figma "Patients"
/// frame.
///
/// Not a roster the doctor maintains — the SRS puts that under out-of-scope
/// "Provider-Side / Clinical Workflow Features (EHR Territory)". A patient is
/// here because they booked, which is the consent the SRS describes: "when
/// the patient makes a booking he is agreeing to share his medical records".
/// So there is nothing to add, edit or delete here, and no clinical status
/// invented for anyone: the design's Condition, Status and Priority columns
/// show the last reason for a visit, what the appointments say, and the next
/// visit, and its tabs filter by that status.
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key, required this.onPatientTap, this.clock});

  final ValueChanged<DoctorPatient> onPatientTap;

  /// Stands in for the time of day in tests.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _PatientsViewModel>(
      onInit: (store) => store.dispatch(const LoadAppointmentsAction()),
      converter: (store) => _PatientsViewModel.fromStore(
        store,
        clock?.call() ?? DateTime.now(),
      ),
      builder: (context, vm) =>
          _PatientsView(vm: vm, onPatientTap: onPatientTap),
    );
  }
}

class _PatientsViewModel {
  const _PatientsViewModel({
    required this.patients,
    required this.appointments,
    required this.now,
    required this.isLoading,
    required this.hasLoaded,
    required this.errorMessage,
  });

  factory _PatientsViewModel.fromStore(Store<AppState> store, DateTime now) {
    final state = store.state.appointmentsState;
    return _PatientsViewModel(
      patients: patientsFromAppointments(state.appointments, now: now),
      appointments: state.appointments,
      now: now,
      isLoading: state.isLoading,
      hasLoaded: state.hasLoadedOnce,
      errorMessage: state.errorMessage,
    );
  }

  final List<DoctorPatient> patients;
  final List<Appointment> appointments;
  final DateTime now;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  summary.PatientStatus statusOf(DoctorPatient p) =>
      summary.patientStatus(appointments, p.id, now);
}

class _PatientsView extends StatefulWidget {
  const _PatientsView({required this.vm, required this.onPatientTap});

  final _PatientsViewModel vm;
  final ValueChanged<DoctorPatient> onPatientTap;

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  PatientFilter _tab = PatientFilter.all;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    // The top bar's search, when this page is inside the doctor's shell.
    final query = DoctorSearchScope.maybeOf(context)?.value.trim() ?? '';
    final patients = vm.patients
        .where((p) => _tab.keeps(vm.statusOf(p)))
        .where((p) => summary.patientMatches(p, query))
        .toList();
    final waiting = summary.awaitingAcceptance(vm.appointments, vm.now);

    final Widget body;
    if (vm.errorMessage != null && vm.patients.isEmpty) {
      body = _Notice(
        icon: Icons.error_outline,
        title: 'Your patients could not be loaded',
        body: vm.errorMessage!,
        tone: _NoticeTone.problem,
      );
    } else if (!vm.hasLoaded && vm.isLoading) {
      body =
          const Center(child: CircularProgressIndicator(color: AppColors.teal));
    } else if (vm.patients.isEmpty) {
      body = const _Notice(
        icon: Icons.people_outline,
        title: 'No patients yet',
        body: 'A patient appears here once they book an appointment '
            'with you. Booking is how they agree to share their '
            'records, so there is nothing to add by hand.',
        tone: _NoticeTone.calm,
      );
    } else if (patients.isEmpty) {
      body = _Notice(
        icon: Icons.search_off,
        title: query.isNotEmpty
            ? 'Nobody matches "$query"'
            : 'No patients under ${_tab.label}',
        body: query.isNotEmpty
            ? 'Search looks at name, patient ID, visit reason, email and phone.'
            : 'Choose another tab to see the rest.',
        tone: _NoticeTone.calm,
      );
    } else {
      body = _PatientTable(
        patients: patients,
        statusOf: vm.statusOf,
        lastVisitOf: (p) => summary.lastVisit(vm.appointments, p.id, vm.now),
        now: vm.now,
        onRowTap: widget.onPatientTap,
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(31, 0, 38, 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(33, 30, 33, 22),
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(total: vm.patients.length),
            const SizedBox(height: 14),
            Row(
              children: [
                PatientFilterChips(
                  selected: _tab,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(width: 12),
                // Takes what room the tabs leave, up to its design width.
                if (waiting > 0)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _AlertBar(waiting: waiting),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

const Color _panelBg = Color(0xFFE3F5F6);
const Color _aqua = Color(0xFF6DD0D8);
const Color _muted = Color(0xFF7C8B8D);

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients',
                style:
                    TextStyle(fontSize: 34, color: Colors.black, height: 1.2),
              ),
              SizedBox(height: 6),
              Text(
                'Everyone who has booked an appointment with you.',
                style: TextStyle(fontSize: 17, color: _muted),
              ),
            ],
          ),
        ),
        Text(
          'Total: $total',
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ],
    );
  }
}

/// Bookings waiting on the doctor, as on the dashboard. Opens Appointments,
/// where accepting happens.
class _AlertBar extends StatelessWidget {
  const _AlertBar({required this.waiting});

  final int waiting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2EE7A),
      child: InkWell(
        onTap: () => context.go(AppRoutes.doctorAppointments),
        child: Container(
          height: 26,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded,
                  size: 18, color: AppColors.amber),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.tight,
                child: Text(
                  waiting == 1
                      ? '1 booking is waiting for you to accept'
                      : '$waiting bookings are waiting for you to accept',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF8A7A00)),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFF8A7A00)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notice ──────────────────────────────────────────────────────────────────
enum _NoticeTone { calm, problem }

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final problem = tone == _NoticeTone.problem;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: problem ? AppColors.alertBg : AppColors.cardBg,
          border: Border.all(
              color: problem ? AppColors.alertBorder : AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 30,
                color: problem ? AppColors.amber : AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Patient table ────────────────────────────────────────────────────────────

/// The column labels on the panel, then the rows on a white card with the
/// curved teal edge, scrolling inside it so the page itself does not.
class _PatientTable extends StatefulWidget {
  const _PatientTable({
    required this.patients,
    required this.statusOf,
    required this.lastVisitOf,
    required this.now,
    required this.onRowTap,
  });

  final List<DoctorPatient> patients;
  final summary.PatientStatus Function(DoctorPatient) statusOf;
  final DateTime? Function(DoctorPatient) lastVisitOf;
  final DateTime now;
  final ValueChanged<DoctorPatient> onRowTap;

  @override
  State<_PatientTable> createState() => _PatientTableState();
}

class _PatientTableState extends State<_PatientTable> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow windows scroll the table sideways rather than crush it.
        const minWidth = 820.0;
        final width = math.max(constraints.maxWidth, minWidth);
        final table = SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(30, 0, 34, 0),
                child: PatientTableHeader(),
              ),
              Container(
                height: 2,
                margin: const EdgeInsets.only(top: 8, bottom: 14),
                color: const Color(0xFFCFE3E5),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _aqua,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
                    child: PatientTableList(
                      itemCount: widget.patients.length,
                      itemBuilder: (context, i) {
                        final p = widget.patients[i];
                        return PatientTableRow(
                          patient: p,
                          status: widget.statusOf(p),
                          lastVisit: widget.lastVisitOf(p),
                          now: widget.now,
                          onOpenProfile: () => widget.onRowTap(p),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return constraints.maxWidth >= minWidth
            ? table
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: table);
      },
    );
  }
}

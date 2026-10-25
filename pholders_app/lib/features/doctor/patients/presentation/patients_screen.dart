import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../data/doctor_patient.dart';

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
  });
  /// Built from a real patient, so the older detail screens can keep their
  /// type while showing what the appointments actually say.
  factory Patient.fromDoctorPatient(DoctorPatient p) => Patient(
        id: '${p.id}',
        name: p.name,
        condition: p.lastReason ?? 'No reason recorded',
        lastActivity: p.lastSeen == null
            ? 'No visit recorded'
            : _PatientRow._date(p.lastSeen),
        // Nothing in the data supports a clinical judgement, so none is made.
        status: PatientStatus.stable,
        priority: 'Not set',
        category: PatientCategory.outpatient,
        avatarInitials: p.initials,
        email: p.email,
        phone: p.phone,
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
      );
}

// ─── Patients screen ─────────────────────────────────────────────────────────
/// Everyone who has booked this doctor.
///
/// Not a roster the doctor maintains — the SRS puts that under out-of-scope
/// "Provider-Side / Clinical Workflow Features (EHR Territory)". A patient is
/// here because they booked, which is the consent the SRS describes: "when
/// the patient makes a booking he is agreeing to share his medical records".
/// So there is nothing to add, edit or delete here, and no clinical status
/// invented for anyone.
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key, required this.onPatientTap});

  final ValueChanged<DoctorPatient> onPatientTap;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _PatientsViewModel>(
      onInit: (store) => store.dispatch(const LoadAppointmentsAction()),
      converter: _PatientsViewModel.fromStore,
      builder: (context, vm) => _PatientsView(vm: vm, onPatientTap: onPatientTap),
    );
  }
}

class _PatientsViewModel {
  const _PatientsViewModel({
    required this.patients,
    required this.isLoading,
    required this.hasLoaded,
    required this.errorMessage,
  });

  factory _PatientsViewModel.fromStore(Store<AppState> store) {
    final state = store.state.appointmentsState;
    return _PatientsViewModel(
      patients: patientsFromAppointments(state.appointments),
      isLoading: state.isLoading,
      hasLoaded: state.hasLoadedOnce,
      errorMessage: state.errorMessage,
    );
  }

  final List<DoctorPatient> patients;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
}

class _PatientsView extends StatefulWidget {
  const _PatientsView({required this.vm, required this.onPatientTap});

  final _PatientsViewModel vm;
  final ValueChanged<DoctorPatient> onPatientTap;

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorPatient> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.vm.patients;
    return widget.vm.patients.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.email ?? '').toLowerCase().contains(q) ||
          (p.phone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final patients = _filtered;

    return Container(
      color: AppColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(total: vm.patients.length),
                  const SizedBox(height: 16),
                  if (vm.errorMessage != null)
                    _Notice(
                      icon: Icons.error_outline,
                      title: 'Your patients could not be loaded',
                      body: vm.errorMessage!,
                      tone: _NoticeTone.problem,
                    )
                  else if (!vm.hasLoaded && vm.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                    )
                  else if (vm.patients.isEmpty)
                    const _Notice(
                      icon: Icons.people_outline,
                      title: 'No patients yet',
                      body: 'A patient appears here once they book an appointment '
                          'with you. Booking is how they agree to share their '
                          'records, so there is nothing to add by hand.',
                      tone: _NoticeTone.calm,
                    )
                  else if (patients.isEmpty)
                    _Notice(
                      icon: Icons.search_off,
                      title: 'Nobody matches "$_query"',
                      body: 'Search looks at name, email and phone number.',
                      tone: _NoticeTone.calm,
                    )
                  else
                    _PatientTable(
                      patients: patients,
                      onRowTap: widget.onPatientTap,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Patients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            height: 38,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total == 1 ? '1 patient' : '$total patients',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Everyone who has booked an appointment with you.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: problem ? AppColors.alertBg : AppColors.cardBg,
        border: Border.all(color: problem ? AppColors.alertBorder : AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: problem ? AppColors.amber : AppColors.textSecondary),
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
    );
  }
}

// ─── Patient table ────────────────────────────────────────────────────────────
class _PatientTable extends StatelessWidget {
  const _PatientTable({required this.patients, required this.onRowTap});

  final List<DoctorPatient> patients;
  final ValueChanged<DoctorPatient> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: const Row(
              children: [
                Expanded(flex: 26, child: _HeaderCell('Patient')),
                Expanded(flex: 24, child: _HeaderCell('Contact')),
                Expanded(flex: 10, child: _HeaderCell('Visits')),
                Expanded(flex: 20, child: _HeaderCell('Last seen')),
                Expanded(flex: 20, child: _HeaderCell('Next appointment')),
              ],
            ),
          ),
          for (final patient in patients)
            _PatientRow(patient: patient, onTap: () => onRowTap(patient)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ─── Patient row ──────────────────────────────────────────────────────────────
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient, required this.onTap});

  final DoctorPatient patient;
  final VoidCallback onTap;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')} '
        '${_months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 26,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.tealLight,
                    child: Text(
                      patient.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (patient.lastReason != null)
                          Text(
                            patient.lastReason!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.email ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                  if (patient.phone != null)
                    Text(
                      patient.phone!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                '${patient.visits}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _date(patient.lastSeen),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                  Text(
                    patient.hasCompletedVisit ? 'Consulted' : 'Not yet consulted',
                    style: TextStyle(
                      fontSize: 11,
                      color: patient.hasCompletedVisit
                          ? AppColors.tealDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                patient.nextVisit == null ? '—' : _date(patient.nextVisit),
                style: TextStyle(
                  fontSize: 12.5,
                  color: patient.nextVisit == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

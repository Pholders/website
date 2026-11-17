import 'package:flutter/material.dart';

import '../../dashboard/data/dashboard_summary.dart' as summary;
import '../../dashboard/presentation/patient_status_pill.dart';
import '../../prescriptions/presentation/new_prescription_dialog.dart';
import '../data/doctor_patient.dart';

/// The patient table's columns and rows, shared by the Patients page and the
/// dashboard so the two always look and behave the same: the same columns,
/// and a click on a row or its three dots opens the patient's actions.

const Color _panelBg = Color(0xFFE3F5F6);
const Color _darkTeal = Color(0xFF2E9FA5);

// Column shares, from the design's Name / Condition / Last activity / Status
// / Priority / Action starts.
const _nameFlex = 18;
const _conditionFlex = 17;
const _activityFlex = 15;
const _statusFlex = 16;
const _nextFlex = 13;
const _actionWidth = 90.0;

/// The filters above the table: everyone, or one [summary.PatientStatus].
/// Shared so the dashboard and the Patients page offer the same ones.
enum PatientFilter {
  all('All', null),
  upcoming('Upcoming visit', summary.PatientStatus.upcomingVisit),
  today('Visit today', summary.PatientStatus.visitToday),
  awaiting('Awaiting acceptance', summary.PatientStatus.awaitingAcceptance),
  seen('Seen', summary.PatientStatus.seen);

  const PatientFilter(this.label, this.status);
  final String label;
  final summary.PatientStatus? status;

  bool keeps(summary.PatientStatus of) => status == null || of == status;
}

/// One row of [PatientFilter] chips, the selected one in black.
class PatientFilterChips extends StatelessWidget {
  const PatientFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PatientFilter selected;
  final ValueChanged<PatientFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final filter in PatientFilter.values)
          _FilterChip(
            label: filter.label,
            selected: filter == selected,
            onTap: () => onSelected(filter),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: selected ? Colors.white : const Color(0xFF6C6C6C),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The column labels, lined up with [PatientTableRow].
class PatientTableHeader extends StatelessWidget {
  const PatientTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: _nameFlex, child: _HeaderCell('Name')),
        Expanded(
            flex: _conditionFlex, child: _HeaderCell('Last reason for visit')),
        Expanded(flex: _activityFlex, child: _HeaderCell('Last activity')),
        Expanded(flex: _statusFlex, child: _HeaderCell('Status')),
        Expanded(flex: _nextFlex, child: _HeaderCell('Next visit')),
        SizedBox(width: _actionWidth, child: _HeaderCell('Action')),
      ],
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
      style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
    );
  }
}

// ─── Patient row ──────────────────────────────────────────────────────────────

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "04 Nov 2026", or "—" when there is no date.
String formatPatientDate(DateTime? value) {
  if (value == null) return '—';
  return '${value.day.toString().padLeft(2, '0')} '
      '${_months[value.month - 1]} ${value.year}';
}

class PatientTableRow extends StatelessWidget {
  const PatientTableRow({
    super.key,
    required this.patient,
    required this.status,
    required this.lastVisit,
    required this.now,
    required this.onOpenProfile,
  });

  final DoctorPatient patient;
  final summary.PatientStatus status;
  final DateTime? lastVisit;
  final DateTime now;

  /// Opens the patient's profile; it is one of the choices in the menu.
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    const cell = TextStyle(
      fontSize: 11,
      color: Color(0xFF6C6C6C),
      fontWeight: FontWeight.w500,
    );

    // A click on the row opens the same menu as its three dots; the profile
    // is one of the choices in it, not where a stray click lands.
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () =>
          showPatientActions(context, patient, onOpenProfile: onOpenProfile),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(
              flex: _nameFlex,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: _darkTeal,
                    // The photo when there is one; the initials show through
                    // if it is missing or fails to load.
                    foregroundImage: patient.avatarUrl == null
                        ? null
                        : NetworkImage(patient.avatarUrl!),
                    onForegroundImageError:
                        patient.avatarUrl == null ? null : (_, __) {},
                    child: Text(
                      patient.initials,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(patient.name,
                        overflow: TextOverflow.ellipsis, style: cell),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: _conditionFlex,
              child: Text(
                patient.lastReason ?? '—',
                overflow: TextOverflow.ellipsis,
                style: cell,
              ),
            ),
            Expanded(
              flex: _activityFlex,
              child: Tooltip(
                message: formatPatientDate(lastVisit),
                child: Text(summary.daysAgoLabel(lastVisit, now), style: cell),
              ),
            ),
            Expanded(
              flex: _statusFlex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PatientStatusPill(status),
              ),
            ),
            Expanded(
              flex: _nextFlex,
              child: Text(
                formatPatientDate(patient.nextVisit),
                style: const TextStyle(fontSize: 13, color: _darkTeal),
              ),
            ),
            SizedBox(
              width: _actionWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_vert,
                      size: 20, color: Color(0xFF4A4A4A)),
                  onPressed: () => showPatientActions(context, patient,
                      onOpenProfile: onOpenProfile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What can be done with a patient, opened from the row or its three dots.
enum PatientAction {
  viewProfile('View Patient Profile'),
  createPrescription('Create Prescription'),
  sendMedicationReminder('Send Medication Reminder'),
  sendSafetyAlert('Send Safety Alert'),
  notifyPrescriptionReady('Notify Prescription Ready');

  const PatientAction(this.label);
  final String label;

  /// The backend has no endpoint yet for a doctor to message a patient, so
  /// these are shown, as designed, but cannot be chosen. Remove an action
  /// from here once its endpoint exists and it is handled below.
  bool get available => switch (this) {
        viewProfile || createPrescription => true,
        _ => false,
      };
}

/// Shows the patient's actions and carries out the one chosen.
Future<void> showPatientActions(
  BuildContext context,
  DoctorPatient patient, {
  required VoidCallback onOpenProfile,
}) async {
  final action = await showDialog<PatientAction>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => PatientActionsMenu(patient: patient),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case PatientAction.viewProfile:
      onOpenProfile();
    case PatientAction.createPrescription:
      await showDialog<bool>(
        context: context,
        builder: (_) => NewPrescriptionDialog(patientId: patient.id),
      );
    case PatientAction.sendMedicationReminder:
    case PatientAction.sendSafetyAlert:
    case PatientAction.notifyPrescriptionReady:
      // Not choosable; see [PatientAction.available].
      break;
  }
}

/// One line of an [ActionsMenu]. One that cannot be chosen yet is shown
/// greyed, with "Not available yet" on hover, so the design stays whole.
class ActionsMenuItem<T> {
  const ActionsMenuItem(this.label, this.value, {this.enabled = true});
  final String label;
  final T value;
  final bool enabled;
}

/// The small card of actions: a round close button, then one underlined
/// line per action. Shown as a dialog; it closes with the chosen value.
/// Used for a patient's actions and for a medication's.
class ActionsMenu<T> extends StatelessWidget {
  const ActionsMenu({super.key, required this.items, this.width = 260});

  final List<ActionsMenuItem<T>> items;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 6,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEDEDED)),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Tooltip(
                  message: 'Close',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black87, width: 1.4),
                      ),
                      child: const Icon(Icons.close,
                          size: 11, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items) _ActionLine<T>(item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A patient's actions.
class PatientActionsMenu extends StatelessWidget {
  const PatientActionsMenu({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  Widget build(BuildContext context) {
    return ActionsMenu<PatientAction>(items: [
      for (final action in PatientAction.values)
        ActionsMenuItem(action.label, action, enabled: action.available),
    ]);
  }
}

class _ActionLine<T> extends StatelessWidget {
  const _ActionLine(this.item);

  final ActionsMenuItem<T> item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled;
    final line = InkWell(
      onTap: enabled ? () => Navigator.pop(context, item.value) : null,
      hoverColor: _panelBg,
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 9, 2, 5),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFD9D9D9), width: 1.2),
          ),
        ),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 13,
            color: enabled ? const Color(0xFF6C6C6C) : const Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
    return enabled ? line : Tooltip(message: 'Not available yet', child: line);
  }
}

/// The table's rows in a scrolling list with the Patients page's scrollbar:
/// a teal thumb on a pale track, always shown, so it is plain the list goes
/// on. Used by the Patients page and the dashboard.
class PatientTableList extends StatefulWidget {
  const PatientTableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.only(right: 24),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Room on the right keeps the rows clear of the scrollbar.
  final EdgeInsets padding;

  @override
  State<PatientTableList> createState() => _PatientTableListState();
}

class _PatientTableListState extends State<PatientTableList> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _scroll,
      thumbVisibility: true,
      thumbColor: _darkTeal,
      trackVisibility: true,
      trackColor: const Color(0xFFE0F4F5),
      thickness: 6,
      radius: const Radius.circular(3),
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}

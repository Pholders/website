import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../appointments/data/models/appointment.dart';
import '../../appointments/redux/appointments_actions.dart';
import '../data/models/medicine_draft.dart';
import '../data/prescriptions_repository.dart';
import '../redux/prescriptions_actions.dart';

const _teal = Color(0xFF2EC4C4);
const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);
const _danger = Color(0xFFFF6B6B);

/// Creates a real prescription against one of the doctor's appointments.
///
/// The backend cannot issue a prescription outside a consultation, so the
/// appointment is chosen first and it determines the patient — there is no
/// patient picker, by design.
///
/// Saving runs three kinds of call: create the prescription, then one per
/// medicine. The script is left unsigned; signing is a separate, deliberate
/// action from the row menu because it cannot be undone.
class NewPrescriptionDialog extends StatefulWidget {
  const NewPrescriptionDialog({super.key, this.patientId});

  /// When set, only this patient's consultations are offered, and if there
  /// is just one it is chosen already. Used from the Patients page.
  final int? patientId;

  @override
  State<NewPrescriptionDialog> createState() => _NewPrescriptionDialogState();
}

class _NewPrescriptionDialogState extends State<NewPrescriptionDialog> {
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Appointment? _appointment;

  /// The one consultation for [NewPrescriptionDialog.patientId], if there is
  /// exactly one and nothing has been chosen yet.
  Appointment? _onlyConsultationFor(List<Appointment> appointments) {
    final id = widget.patientId;
    if (id == null) return null;
    final theirs = appointments.where((a) => a.patientId == id).toList();
    return theirs.length == 1 ? theirs.single : null;
  }
  final List<MedicineDraft> _medicines = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // The appointment list may not have been fetched yet in this session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context)
            .dispatch(const LoadAppointmentsAction());
      }
    });
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMedicine() async {
    final medicine = await showDialog<MedicineDraft>(
      context: context,
      builder: (_) => const _MedicineDialog(),
    );
    if (medicine != null) setState(() => _medicines.add(medicine));
  }

  void _submit() {
    final appointment = _appointment ??
        _onlyConsultationFor(
            StoreProvider.of<AppState>(context).state.appointmentsState.appointments);
    String? problem;
    if (appointment == null) {
      problem = 'Choose the consultation this prescription is for.';
    } else if (_diagnosisCtrl.text.trim().isEmpty) {
      problem = 'Enter a diagnosis.';
    } else if (_medicines.isEmpty) {
      // Not just validation for its own sake: a prescription with no
      // medicines cannot be signed, so it would be unusable.
      problem = 'Add at least one medicine, or it cannot be signed later.';
    }

    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);

    StoreProvider.of<AppState>(context).dispatch(
      CreatePrescriptionAction(
        appointmentId: appointment!.id,
        diagnosis: _diagnosisCtrl.text.trim(),
        clinicalNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        medicines: List.of(_medicines),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _FormViewModel>(
      converter: _FormViewModel.fromStore,
      onWillChange: (previous, next) {
        // Close once the whole sequence has saved.
        if (previous?.createdId == null && next.createdId != null) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, vm) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Prescriptions are issued against a consultation, which '
                    'determines the patient.',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Consultation'),
                          _AppointmentPicker(
                            appointments: widget.patientId == null
                                ? vm.appointments
                                : vm.appointments
                                    .where((a) =>
                                        a.patientId == widget.patientId)
                                    .toList(),
                            isLoading: vm.appointmentsLoading,
                            selected:
                                _appointment ?? _onlyConsultationFor(vm.appointments),
                            onChanged: (a) => setState(() => _appointment = a),
                          ),
                          const SizedBox(height: 16),

                          _label('Diagnosis'),
                          _field(_diagnosisCtrl, 'e.g. Upper respiratory infection'),
                          const SizedBox(height: 16),

                          _label('Clinical notes (optional)'),
                          _field(_notesCtrl, 'Anything the pharmacy should know',
                              maxLines: 2),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              _label('Medicines'),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _addMedicine,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add medicine'),
                              ),
                            ],
                          ),
                          if (_medicines.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'None yet. A prescription needs at least one '
                                'medicine before it can be signed.',
                                style: TextStyle(
                                    fontSize: 12, color: _textSecondary),
                              ),
                            )
                          else
                            ...List.generate(_medicines.length, (i) {
                              final m = _medicines[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.summary,
                                        style: const TextStyle(
                                            fontSize: 13, color: _textPrimary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      color: _textSecondary,
                                      onPressed: () =>
                                          setState(() => _medicines.removeAt(i)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null || vm.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error ?? vm.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: vm.isCreating
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: _teal),
                        onPressed: vm.isCreating ? null : _submit,
                        child: vm.isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create prescription'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
      );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _textSecondary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
  }
}

/// Picks which consultation the prescription belongs to.
class _AppointmentPicker extends StatelessWidget {
  const _AppointmentPicker({
    required this.appointments,
    required this.isLoading,
    required this.selected,
    required this.onChanged,
  });

  final List<Appointment> appointments;
  final bool isLoading;
  final Appointment? selected;
  final ValueChanged<Appointment?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading && appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Loading consultations...',
            style: TextStyle(fontSize: 12, color: _textSecondary)),
      );
    }

    if (appointments.isEmpty) {
      // Worth spelling out: the endpoint only returns appointments the doctor
      // has not accepted yet, so an empty list is not an empty diary.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No consultations awaiting you. A prescription can only be issued '
          'against one, so there is nothing to prescribe for yet.',
          style: TextStyle(fontSize: 12, color: _danger),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Appointment>(
          value: selected,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 260,
          hint: const Text('Choose a consultation',
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          style: const TextStyle(fontSize: 13, color: _textPrimary),
          items: [
            for (final a in appointments)
              DropdownMenuItem<Appointment>(
                value: a,
                child: Text(
                  '${a.patientName} — ${a.formattedDate} ${a.timeSlot ?? ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Captures one medicine, including the two fields the backend enforces as
/// enums: dosage form and route of administration.
class _MedicineDialog extends StatefulWidget {
  const _MedicineDialog();

  @override
  State<_MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<_MedicineDialog> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _frequencyCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  MedicineDosageForm _form = MedicineDosageForm.tablet;
  MedicineRoute _route = MedicineRoute.oral;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _quantityCtrl.dispose();
    _frequencyCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    String? problem;
    if (_nameCtrl.text.trim().isEmpty) {
      problem = 'Enter the medicine name.';
    } else if (_dosageCtrl.text.trim().isEmpty) {
      problem = 'Enter the dosage, e.g. 500mg.';
    } else if (quantity == null || quantity <= 0) {
      problem = 'Quantity must be a number greater than zero.';
    } else if (_frequencyCtrl.text.trim().isEmpty) {
      problem = 'Enter how often it is taken.';
    }

    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    Navigator.of(context).pop(
      MedicineDraft(
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        form: _form,
        quantity: quantity!,
        frequency: _frequencyCtrl.text.trim(),
        route: _route,
        duration: _durationCtrl.text.trim().isEmpty
            ? null
            : _durationCtrl.text.trim(),
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add medicine',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                const SizedBox(height: 16),
                _text(_nameCtrl, 'Medicine name', 'e.g. Amoxicillin'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _text(_dosageCtrl, 'Dosage', 'e.g. 500mg')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _text(_quantityCtrl, 'Quantity', 'e.g. 21',
                          keyboard: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _enum<MedicineDosageForm>(
                        'Form',
                        MedicineDosageForm.values,
                        _form,
                        (v) => setState(() => _form = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _enum<MedicineRoute>(
                        'Route',
                        MedicineRoute.values,
                        _route,
                        (v) => setState(() => _route = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _text(_frequencyCtrl, 'Frequency',
                          'e.g. Three times daily'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          _text(_durationCtrl, 'Duration', 'e.g. 7 days'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _text(_instructionsCtrl, 'Instructions',
                    'e.g. Take with food'),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _danger,
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _teal),
                      onPressed: _submit,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(TextEditingController c, String label, String hint,
      {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _textSecondary),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
          ),
        ),
      ],
    );
  }

  /// Dropdown over a backend enum, so an invalid value cannot be submitted.
  Widget _enum<T extends Enum>(
    String label,
    List<T> values,
    T selected,
    ValueChanged<T> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selected,
              isExpanded: true,
              isDense: true,
              menuMaxHeight: 260,
              style: const TextStyle(fontSize: 13, color: _textPrimary),
              items: [
                for (final v in values)
                  DropdownMenuItem<T>(value: v, child: Text(v.name)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Store bindings ------------------------------------------------------------

class _FormViewModel {
  const _FormViewModel({
    required this.appointments,
    required this.appointmentsLoading,
    required this.isCreating,
    this.errorMessage,
    this.createdId,
  });

  factory _FormViewModel.fromStore(Store<AppState> store) {
    return _FormViewModel(
      appointments: store.state.appointmentsState.appointments,
      appointmentsLoading: store.state.appointmentsState.isLoading,
      isCreating: store.state.prescriptionsState.isCreating,
      errorMessage: store.state.prescriptionsState.errorMessage,
      createdId: store.state.prescriptionsState.lastCreatedId,
    );
  }

  final List<Appointment> appointments;
  final bool appointmentsLoading;
  final bool isCreating;
  final String? errorMessage;
  final int? createdId;
}

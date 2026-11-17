import '../prescriptions_repository.dart';

/// One medicine as captured on the new-prescription form, before it is sent.
///
/// The backend stores medicines as separate rows added after the prescription
/// exists, so a draft is held here until the prescription has an id.
class MedicineDraft {
  const MedicineDraft({
    required this.name,
    required this.dosage,
    required this.form,
    required this.quantity,
    required this.frequency,
    required this.route,
    this.duration,
    this.instructions,
  });

  final String name;
  final String dosage;
  final MedicineDosageForm form;
  final int quantity;
  final String frequency;
  final MedicineRoute route;
  final String? duration;
  final String? instructions;

  /// "Amoxicillin 500mg — 3 times daily" for the review list on the form.
  String get summary {
    final parts = <String>[name, dosage, frequency];
    return parts.where((p) => p.trim().isNotEmpty).join(' · ');
  }
}

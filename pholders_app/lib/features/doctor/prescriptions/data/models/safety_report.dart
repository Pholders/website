import 'package:equatable/equatable.dart';

/// How safe the backend judged a prescription to be overall.
///
/// Values come from `DrugInteractionService.generateSafetyReport`. It starts a
/// report as `REQUIRES_REVIEW` and then settles on one of the other three, so
/// all four can appear.
enum SafetyLevel { safe, cautionRequired, highRisk, requiresReview, unknown }

/// One drug-versus-drug interaction.
class DrugInteraction extends Equatable {
  const DrugInteraction({
    required this.drugOne,
    required this.drugTwo,
    required this.interaction,
    required this.recommendation,
    required this.level,
  });

  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      drugOne: _str(json['drug1']) ?? '',
      drugTwo: _str(json['drug2']) ?? '',
      interaction: _str(json['interaction']) ?? '',
      recommendation: _str(json['recommendation']) ?? '',
      level: _str(json['level']) ?? '',
    );
  }

  final String drugOne;
  final String drugTwo;

  /// What the interaction is, e.g. "CONTRAINDICATED - DO NOT USE TOGETHER".
  final String interaction;
  final String recommendation;

  /// 'SEVERE' or 'MODERATE'.
  final String level;

  String get pair => '$drugOne + $drugTwo';

  @override
  List<Object?> get props => [drugOne, drugTwo, interaction, level];
}

/// A medicine flagged against one of the patient's conditions.
class Contraindication extends Equatable {
  const Contraindication({required this.warning, required this.severity});

  factory Contraindication.fromJson(Map<String, dynamic> json) {
    return Contraindication(
      warning: _str(json['warning']) ?? 'Contraindication flagged',
      severity: _str(json['severity']) ?? '',
    );
  }

  final String warning;
  final String severity;

  @override
  List<Object?> get props => [warning, severity];
}

/// The result of `POST /prescriptions/:id/check-interactions`.
///
/// The check runs over the medicines already on the prescription. It is worth
/// running before signing, because a signed prescription can no longer be
/// edited.
class SafetyReport extends Equatable {
  const SafetyReport({
    required this.level,
    this.medicinesChecked = const [],
    this.severe = const [],
    this.moderate = const [],
    this.mild = const [],
    this.contraindications = const [],
    this.recommendedActions = const [],
    this.checkedAt,
  });

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    final checks = json['checks'];
    final interactions = checks is Map<String, dynamic>
        ? checks['drugInteractions']
        : null;

    List<DrugInteraction> band(String key) {
      final raw = interactions is Map<String, dynamic> ? interactions[key] : null;
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DrugInteraction.fromJson)
          .toList();
    }

    final contra = checks is Map<String, dynamic>
        ? checks['patientContraindications']
        : null;

    return SafetyReport(
      level: _levelFrom(_str(json['overallSafety'])),
      medicinesChecked: (json['medicinesChecked'] as List<dynamic>? ?? [])
          .map((m) => m.toString())
          .toList(),
      severe: band('severe'),
      moderate: band('moderate'),
      mild: band('mild'),
      contraindications: contra is List
          ? contra
              .whereType<Map<String, dynamic>>()
              .map(Contraindication.fromJson)
              .toList()
          : const [],
      recommendedActions: (json['recommendedActions'] as List<dynamic>? ?? [])
          .map((a) => a.toString())
          .toList(),
      checkedAt: DateTime.tryParse(_str(json['timestamp']) ?? ''),
    );
  }

  final SafetyLevel level;
  final List<String> medicinesChecked;
  final List<DrugInteraction> severe;
  final List<DrugInteraction> moderate;
  final List<DrugInteraction> mild;
  final List<Contraindication> contraindications;
  final List<String> recommendedActions;
  final DateTime? checkedAt;

  /// True when nothing at all was flagged.
  bool get isClear =>
      severe.isEmpty && moderate.isEmpty && mild.isEmpty && contraindications.isEmpty;

  /// Headline for the result banner.
  String get headline {
    switch (level) {
      case SafetyLevel.safe:
        return 'No interactions found';
      case SafetyLevel.cautionRequired:
        return 'Caution required';
      case SafetyLevel.highRisk:
        return 'Do not dispense';
      case SafetyLevel.requiresReview:
        return 'Needs review';
      case SafetyLevel.unknown:
        return 'Check complete';
    }
  }

  static SafetyLevel _levelFrom(String? raw) {
    switch (raw) {
      case 'SAFE':
        return SafetyLevel.safe;
      case 'CAUTION_REQUIRED':
        return SafetyLevel.cautionRequired;
      case 'HIGH_RISK':
        return SafetyLevel.highRisk;
      case 'REQUIRES_REVIEW':
        return SafetyLevel.requiresReview;
      default:
        return SafetyLevel.unknown;
    }
  }

  @override
  List<Object?> get props =>
      [level, medicinesChecked, severe, moderate, mild, contraindications];
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

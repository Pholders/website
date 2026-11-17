import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/safety_report.dart';

void main() {
  group('SafetyReport.fromJson', () {
    // The real shape returned for a prescription with nothing flagged,
    // captured from POST /prescriptions/4/check-interactions.
    test('parses a clean report', () {
      final r = SafetyReport.fromJson(const {
        'timestamp': '2026-09-21T12:03:02.697Z',
        'medicinesChecked': ['Panado'],
        'checks': {
          'drugInteractions': {
            'severe': [],
            'moderate': [],
            'mild': [],
            'warnings': []
          },
          'patientContraindications': [],
          'dosageReview': [{}],
        },
        'overallSafety': 'SAFE',
        'recommendedActions': ['Safe to dispense'],
      });

      expect(r.level, SafetyLevel.safe);
      expect(r.isClear, isTrue);
      expect(r.headline, 'No interactions found');
      expect(r.medicinesChecked, ['Panado']);
      expect(r.recommendedActions, ['Safe to dispense']);
    });

    test('parses a severe interaction and does not read as safe', () {
      final r = SafetyReport.fromJson(const {
        'medicinesChecked': ['Warfarin', 'Aspirin'],
        'checks': {
          'drugInteractions': {
            'severe': [
              {
                'drug1': 'Warfarin',
                'drug2': 'Aspirin',
                'interaction': 'CONTRAINDICATED - DO NOT USE TOGETHER',
                'recommendation': 'Avoid Warfarin with Aspirin.',
                'level': 'SEVERE',
              }
            ],
            'moderate': [],
            'mild': [],
          },
          'patientContraindications': [],
        },
        'overallSafety': 'HIGH_RISK',
        'recommendedActions': [
          'DO NOT DISPENSE - Severe drug interactions detected'
        ],
      });

      expect(r.level, SafetyLevel.highRisk);
      expect(r.isClear, isFalse);
      expect(r.headline, 'Do not dispense');
      expect(r.severe.single.pair, 'Warfarin + Aspirin');
      expect(r.severe.single.level, 'SEVERE');
    });

    test('parses contraindications and caution level', () {
      final r = SafetyReport.fromJson(const {
        'checks': {
          'drugInteractions': {'severe': [], 'moderate': [], 'mild': []},
          'patientContraindications': [
            {
              'warning': 'Ibuprofen may be contraindicated in patients with asthma',
              'severity': 'HIGH',
            }
          ],
        },
        'overallSafety': 'CAUTION_REQUIRED',
        'recommendedActions': ['Review prescription with doctor before dispensing'],
      });

      expect(r.level, SafetyLevel.cautionRequired);
      expect(r.headline, 'Caution required');
      expect(r.contraindications.single.severity, 'HIGH');
      expect(r.isClear, isFalse);
    });

    test('an unrecognised safety value never reads as safe', () {
      final r = SafetyReport.fromJson(const {'overallSafety': 'SOMETHING_NEW'});
      expect(r.level, SafetyLevel.unknown);
      expect(r.level, isNot(SafetyLevel.safe));
    });

    test('survives a response with no checks block at all', () {
      final r = SafetyReport.fromJson(const {'overallSafety': 'SAFE'});
      expect(r.severe, isEmpty);
      expect(r.contraindications, isEmpty);
      expect(r.isClear, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/data/models/claimed_prescription.dart';
import 'package:pholders_app/features/pharmacy/dispensing_queue/redux/dispensing_actions.dart';

/// The shape `GET /prescriptions/pharmacy/claimed` returns.
Map<String, dynamic> _claimed(Map<String, dynamic> extra) => {
      'prescriptionId': 8,
      'prescriptionNumber': 'RX-1791441025728-068FDE87',
      'patientName': 'Thandi Testpatient',
      'patientEmail': 'thandi@example.test',
      'patientPhone': '0712345680',
      'diagnosis': 'Tension headache',
      'claimedAt': '2026-10-08T07:30:18.474Z',
      'medicines': [
        {'name': 'Paracetamol', 'dosage': '500mg', 'quantity': 20, 'frequency': 'four times daily'},
      ],
      ...extra,
    };

void main() {
  group('ClaimedPrescription', () {
    test('reads a claimed script', () {
      final p = ClaimedPrescription.fromJson(_claimed({}));

      expect(p.id, 8);
      expect(p.patientName, 'Thandi Testpatient');
      expect(p.medicines.single.name, 'Paracetamol');
      expect(p.medicines.single.detail, '500mg · 20 · four times daily');
    });

    test('summarises one or two medicines, counts the rest', () {
      final one = ClaimedPrescription.fromJson(_claimed({}));
      expect(one.medicineSummary, 'Paracetamol');

      final three = ClaimedPrescription.fromJson(_claimed({
        'medicines': [
          {'name': 'Paracetamol'},
          {'name': 'Amoxicillin'},
          {'name': 'Ibuprofen'},
        ],
      }));
      expect(three.medicineSummary, 'Paracetamol +2 more');
    });

    test('a script with no medicines says so rather than reading blank', () {
      final p = ClaimedPrescription.fromJson(_claimed({'medicines': []}));
      expect(p.medicineSummary, 'No medicines listed');
    });
  });

  group('dispensing queue state', () {
    Store<AppState> store() =>
        Store<AppState>(appReducer, initialState: AppState.initial());

    test('an empty queue is told apart from one that has not loaded', () {
      final s = store();
      expect(s.state.dispensingState.hasLoadedOnce, isFalse);

      s.dispatch(const DispensingQueueLoadedAction(awaiting: [], dispensed: []));
      expect(s.state.dispensingState.hasLoadedOnce, isTrue);
      expect(s.state.dispensingState.awaiting, isEmpty);
    });

    test('a dispense in flight marks only its own row busy', () {
      final s = store();
      s.dispatch(const DispensePrescriptionAction(prescriptionId: 8));

      expect(s.state.dispensingState.busyIds, {8});
    });

    test('a failed dispense frees the row and says why', () {
      final s = store();
      s.dispatch(const DispensePrescriptionAction(prescriptionId: 8));
      s.dispatch(const DispenseFailedAction(
        prescriptionId: 8,
        errorMessage: 'Prescription is not claimed at your pharmacy',
      ));

      expect(s.state.dispensingState.busyIds, isEmpty);
      expect(s.state.dispensingState.errorMessage, contains('not claimed'));
    });

    test('signing out drops the previous pharmacy queue', () {
      final s = store();
      s.dispatch(DispensingQueueLoadedAction(
        awaiting: [ClaimedPrescription.fromJson(_claimed({}))],
        dispensed: const [],
      ));
      s.dispatch(const LogoutAction());

      expect(s.state.dispensingState.awaiting, isEmpty,
          reason: 'one pharmacy must never see another pharmacy queue');
    });
  });
}

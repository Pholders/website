import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/auth/auth_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_reducer.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_state.dart';

void main() {
  _dispensingTests();
  group('Prescription.fromJson', () {
    // The real row shape from GET /prescriptions/doctor/all, which returns a
    // mapped summary rather than the raw database record.
    test('parses a signed prescription', () {
      final rx = Prescription.fromJson(const {
        'id': 12,
        'prescriptionNumber': 'RX-2026-04821',
        'patient': 'Jane Doe',
        'diagnosis': 'Upper respiratory infection',
        'status': 'signed',
        'createdAt': '2026-03-01T08:15:00Z',
      });

      expect(rx.id, 12);
      expect(rx.number, 'RX-2026-04821');
      expect(rx.patientName, 'Jane Doe');
      expect(rx.status, PrescriptionStatus.signed);
      expect(rx.isSigned, isTrue);
      expect(rx.statusLabel, 'Signed');
      expect(rx.formattedDate, '01 Mar');
    });

    test('an unsigned prescription is not dispensable', () {
      final rx = Prescription.fromJson(const {
        'id': 13,
        'prescriptionNumber': 'RX-2026-04822',
        'patient': 'John Nkosi',
        'status': 'pending',
      });

      expect(rx.status, PrescriptionStatus.pending);
      expect(rx.isSigned, isFalse);
      expect(rx.statusLabel, 'Awaiting signature');
      // No createdAt in the payload, so no date to show.
      expect(rx.formattedDate, '');
    });

    test('an unrecognised status does not masquerade as signed', () {
      final rx = Prescription.fromJson(const {'id': 1, 'status': 'something_new'});
      expect(rx.status, PrescriptionStatus.unknown);
      expect(rx.isSigned, isFalse);
    });
  });

  group('prescriptionsReducer', () {
    const signed = Prescription(
      id: 1,
      number: 'RX-1',
      patientName: 'Jane Doe',
      status: PrescriptionStatus.signed,
    );

    test('loading then loaded clears the spinner and records the fetch', () {
      var state = prescriptionsReducer(
        PrescriptionsState.initial(),
        const LoadPrescriptionsAction(),
      );
      expect(state.isLoading, isTrue);

      state = prescriptionsReducer(
        state,
        const PrescriptionsLoadedAction(prescriptions: [signed]),
      );
      expect(state.isLoading, isFalse);
      expect(state.hasLoadedOnce, isTrue);
      expect(state.prescriptions.single.number, 'RX-1');
    });

    test('a failed sign clears that row busy flag and surfaces the reason', () {
      var state = prescriptionsReducer(
        PrescriptionsState.initial(),
        const SignPrescriptionAction(prescriptionId: 1),
      );
      expect(state.busyIds, contains(1));

      state = prescriptionsReducer(
        state,
        const PrescriptionActionFailedAction(
          prescriptionId: 1,
          errorMessage: 'Cannot sign prescription without medicines',
        ),
      );
      expect(state.busyIds, isEmpty);
      expect(state.errorMessage, 'Cannot sign prescription without medicines');
    });

    test('logging out drops the previous doctor prescriptions', () {
      final loaded = prescriptionsReducer(
        PrescriptionsState.initial(),
        const PrescriptionsLoadedAction(prescriptions: [signed]),
      );
      final state = prescriptionsReducer(loaded, const LogoutAction());

      expect(state.prescriptions, isEmpty);
      expect(state.hasLoadedOnce, isFalse);
    });
  });
}

void _dispensingTests() {
  group('dispensing and revoke detail', () {
    Map<String, dynamic> row(Map<String, dynamic> extra) => {
          'id': 7,
          'prescriptionNumber': 'RX-7',
          'patient': 'Test Patient',
          'diagnosis': 'Flu',
          'status': 'signed',
          'createdAt': '2026-10-06T08:00:00.000Z',
          ...extra,
        };

    test('reads the fields the doctor list now returns', () {
      final p = Prescription.fromJson(row({
        'patientId': 15,
        'appointmentId': 4,
        'isDispensed': true,
        'dispensedAt': '2026-10-07T10:30:00.000Z',
        'dispensedByPharmacyName': 'Clicks Sandton',
      }));

      expect(p.patientId, 15);
      expect(p.appointmentId, 4);
      expect(p.isDispensed, isTrue);
      expect(p.dispensedSummary, contains('Clicks Sandton'));
    });

    test('an undispensed script has no dispensing line', () {
      expect(Prescription.fromJson(row({})).dispensedSummary, isNull);
    });

    test('older responses without the fields still parse', () {
      // The fields were added to getDoctorPrescriptions in Oct 2026; a cached
      // or older server must not break the list.
      final p = Prescription.fromJson(row({}));

      expect(p.patientId, isNull);
      expect(p.isDispensed, isFalse);
      expect(p.dispensedSummary, isNull);
    });

    test('keeps the revoke reason so the row can say why', () {
      final p = Prescription.fromJson(
        row({'status': 'revoked', 'revokeReason': 'Wrong dosage'}),
      );

      expect(p.status, PrescriptionStatus.revoked);
      expect(p.revokeReason, 'Wrong dosage');
    });
  });
}

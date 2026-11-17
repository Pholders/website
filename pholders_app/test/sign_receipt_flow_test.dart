import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/signing_receipt.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/prescriptions_repository.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_middleware.dart';

/// Stands in for the network so the sign flow can be driven end to end.
class _FakeRepository implements PrescriptionsRepository {
  _FakeRepository(this.receipt);

  final SigningReceipt receipt;

  @override
  Future<SigningReceipt> sign(int prescriptionId) async => receipt;

  @override
  Future<List<Prescription>> fetchAll({
    String filter = 'all',
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

SigningReceipt _receipt({String qr = 'PRESCRIPTION|6|tok|123'}) =>
    SigningReceipt.fromJson({
      'prescriptionId': 6,
      'prescriptionNumber': 'RX-6',
      'qrCode': qr,
      'accessLink': qr.isEmpty ? '' : 'https://example.test/qr/tok',
      'signatureMethod': 'RSA-SHA256',
    });

void main() {
  Store<AppState> storeWith(SigningReceipt receipt) => Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createPrescriptionsMiddleware(
          repository: _FakeRepository(receipt),
        ),
      );

  test('signing puts the receipt in the store for the UI to show', () async {
    final store = storeWith(_receipt());

    store.dispatch(const SignPrescriptionAction(prescriptionId: 6));
    await Future<void>.delayed(Duration.zero);

    final stored = store.state.prescriptionsState.signingReceipt;
    expect(stored, isNotNull,
        reason: 'the QR exists only in this response, so it must be kept');
    expect(stored!.qrPayload, 'PRESCRIPTION|6|tok|123');
  });

  test('the refetch after signing does not wipe the receipt', () async {
    final store = storeWith(_receipt());

    store.dispatch(const SignPrescriptionAction(prescriptionId: 6));
    // Let the sign, the dispatch and the list refetch all settle.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(store.state.prescriptionsState.signingReceipt, isNotNull);
    expect(store.state.prescriptionsState.busyIds, isEmpty);
  });

  test('dismissing clears it so the next sign cannot show a stale code',
      () async {
    final store = storeWith(_receipt());
    store.dispatch(const SignPrescriptionAction(prescriptionId: 6));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    store.dispatch(const ClearSigningReceiptAction());

    expect(store.state.prescriptionsState.signingReceipt, isNull);
  });

  test('a response with no code leaves nothing to show', () async {
    final store = storeWith(_receipt(qr: ''));

    store.dispatch(const SignPrescriptionAction(prescriptionId: 6));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(store.state.prescriptionsState.signingReceipt, isNull);
  });
}

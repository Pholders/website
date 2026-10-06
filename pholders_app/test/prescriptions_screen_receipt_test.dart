import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/signing_receipt.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/prescriptions_screen.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';

SigningReceipt _receipt() => SigningReceipt.fromJson({
      'prescriptionId': 6,
      'prescriptionNumber': 'RX-6',
      'qrCode': 'PRESCRIPTION|6|tok|123',
      'accessLink': 'https://example.test/qr/tok',
      'signatureMethod': 'RSA-SHA256',
    });

void main() {
  // The QR and access link are returned once, by the sign call, and no doctor
  // endpoint hands them back later. If the screen fails to open the dialog the
  // code is gone for good, so this is checked at the screen level and not just
  // in the store.
  testWidgets('shows the signing receipt as soon as it reaches the store',
      (tester) async {
    final store = Store<AppState>(appReducer, initialState: AppState.initial());

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: Scaffold(body: PrescriptionsScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Prescription signed'), findsNothing);

    store.dispatch(PrescriptionSignedAction(receipt: _receipt()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Prescription signed'), findsOneWidget);
    expect(find.textContaining('cannot be retrieved'), findsOneWidget);
  });

  testWidgets('does not reopen the dialog on a later rebuild', (tester) async {
    final store = Store<AppState>(appReducer, initialState: AppState.initial());

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: Scaffold(body: PrescriptionsScreen())),
      ),
    );
    store.dispatch(PrescriptionSignedAction(receipt: _receipt()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Any further store activity rebuilds the screen while the receipt is
    // still held; it must not stack a second dialog on top.
    store.dispatch(const LoadPrescriptionsAction());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Prescription signed'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/signing_receipt.dart';
import 'package:pholders_app/features/doctor/prescriptions/presentation/signing_receipt_dialog.dart';

/// The shape `POST /prescriptions/:id/sign` actually returns, copied from
/// prescriptionController.js so a change there shows up as a failure here.
Map<String, dynamic> _signResponse({String? accessLink}) => {
      'prescriptionId': 7,
      'prescriptionNumber': 'RX-1788959046066-B71C89F1',
      'status': 'SIGNED',
      'signatureTimestamp': '2026-10-06T09:15:00.000Z',
      'signatureMethod': 'RSA-SHA256',
      'signatureFingerprint': 'a1b2c3d4e5f6',
      'qrCode': 'PRESCRIPTION|7|ab12cd34|1791268023000',
      'accessLink':
          accessLink ?? 'https://app.pholders.co.za/prescriptions/qr/ab12cd34',
      'medicineCount': 2,
      'auditTrail': {
        'signedBy': 'Dr Claude Testdoc',
        'deviceId': 'device-1',
        'ipAddress': '10.0.0.1',
        'timestamp': '2026-10-06T09:15:00.000Z',
      },
    };

void main() {
  group('SigningReceipt', () {
    test('reads the signing response, including the nested audit trail', () {
      final receipt = SigningReceipt.fromJson(_signResponse());

      expect(receipt.prescriptionId, 7);
      expect(receipt.prescriptionNumber, 'RX-1788959046066-B71C89F1');
      expect(receipt.qrPayload, 'PRESCRIPTION|7|ab12cd34|1791268023000');
      expect(receipt.signatureMethod, 'RSA-SHA256');
      expect(receipt.medicineCount, 2);
      expect(receipt.signedBy, 'Dr Claude Testdoc');
      expect(receipt.signedAt, isNotNull);
      expect(receipt.hasCode, isTrue);
    });

    test('copes with the id coming back as a string', () {
      // The live server really does return "prescriptionId": "5".
      final receipt =
          SigningReceipt.fromJson({..._signResponse(), 'prescriptionId': '5'});

      expect(receipt.prescriptionId, 5);
    });

    test('survives a response with nothing useful in it', () {
      final receipt = SigningReceipt.fromJson({'prescriptionId': 7});

      expect(receipt.hasCode, isFalse,
          reason: 'with no code there is nothing to show, so no dialog');
      expect(receipt.prescriptionNumber, '');
      expect(receipt.signedAt, isNull);
    });

    test('flags a link the patient could never open', () {
      expect(
        SigningReceipt.fromJson(
          _signResponse(accessLink: 'http://localhost:3000/prescriptions/qr/x'),
        ).linkIsUnreachable,
        isTrue,
      );
      expect(SigningReceipt.fromJson(_signResponse()).linkIsUnreachable, isFalse);
    });
  });

  group('SigningReceiptDialog', () {
    Future<void> pump(WidgetTester tester, SigningReceipt receipt) async {
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
      );
      await tester.pumpWidget(
        StoreProvider<AppState>(
          store: store,
          child: MaterialApp(
            home: Scaffold(body: SigningReceiptDialog(receipt: receipt)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the QR and says the code cannot be recovered',
        (tester) async {
      await pump(tester, SigningReceipt.fromJson(_signResponse()));

      expect(find.text('Prescription signed'), findsOneWidget);
      expect(find.textContaining('RX-1788959046066'), findsWidgets);
      expect(find.textContaining('cannot be retrieved'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'the QR painter must handle the real payload');
    });

    testWidgets('warns when the link points at localhost', (tester) async {
      await pump(
        tester,
        SigningReceipt.fromJson(
          _signResponse(accessLink: 'http://localhost:3000/prescriptions/qr/x'),
        ),
      );

      expect(find.textContaining('points at localhost'), findsOneWidget);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/medicine_draft.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/prescription.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/models/signing_receipt.dart';
import 'package:pholders_app/features/doctor/prescriptions/data/prescriptions_repository.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_actions.dart';
import 'package:pholders_app/features/doctor/prescriptions/redux/prescriptions_middleware.dart';
import 'package:pholders_app/shared/widgets/app_feedback.dart';

/// A network stand-in whose sign, revoke and add-medicine calls can fail, and
/// whose list reports whatever the "server" now holds.
class _FakeRepository implements PrescriptionsRepository {
  PrescriptionStatus status = PrescriptionStatus.pending;
  String? revokeReason;

  /// Thrown by sign/revoke after the change is applied, like the backend's
  /// notification email failing.
  ApiException? failAfterSave;

  /// Thrown by sign/revoke before anything changes.
  ApiException? failBeforeSave;

  /// The medicine (by position) whose add call fails.
  int? failMedicineAt;
  int _added = 0;

  Prescription get _row => Prescription(
        id: 6,
        number: 'RX-6',
        patientName: 'Pule Test',
        status: status,
        revokeReason: revokeReason,
      );

  @override
  Future<List<Prescription>> fetchAll({
    String filter = 'all',
    int limit = 50,
    int offset = 0,
  }) async =>
      [_row];

  @override
  Future<SigningReceipt> sign(int prescriptionId) async {
    if (failBeforeSave != null) throw failBeforeSave!;
    status = PrescriptionStatus.signed;
    if (failAfterSave != null) throw failAfterSave!;
    return SigningReceipt.fromJson(const {'prescriptionId': 6, 'qrCode': ''});
  }

  @override
  Future<void> revoke(int prescriptionId, {required String reason}) async {
    if (failBeforeSave != null) throw failBeforeSave!;
    status = PrescriptionStatus.revoked;
    revokeReason = reason;
    if (failAfterSave != null) throw failAfterSave!;
  }

  @override
  Future<int> create({
    required int appointmentId,
    required String diagnosis,
    String? clinicalNotes,
  }) async =>
      6;

  @override
  Future<void> addMedicine({
    required int prescriptionId,
    required String medicineName,
    required String dosage,
    required MedicineDosageForm dosageForm,
    required int quantity,
    required String frequency,
    required MedicineRoute routeOfAdministration,
    String? genericName,
    String? quantityUnit,
    String? duration,
    String? specialInstructions,
    String? scheduleClassification,
  }) async {
    if (_added == failMedicineAt) {
      throw const ApiException(
          message: 'boom', statusCode: 500, kind: ApiErrorKind.http);
    }
    _added++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

const _server500 =
    ApiException(message: 'Email failed', statusCode: 500, kind: ApiErrorKind.http);

MedicineDraft _med(String name) => MedicineDraft(
      name: name,
      dosage: '500mg',
      form: MedicineDosageForm.tablet,
      quantity: 21,
      frequency: 'Three times daily',
      route: MedicineRoute.oral,
    );

void main() {
  late _FakeRepository repo;
  late Store<AppState> store;

  setUp(() {
    repo = _FakeRepository();
    store = Store<AppState>(
      appReducer,
      initialState: AppState.initial(),
      middleware: createPrescriptionsMiddleware(repository: repo),
    );
  });

  group('sign and revoke report what the server ended up holding', () {
    test('a clean sign completes with the reference number', () async {
      final result = Completer<RxActionOutcome>();
      store.dispatch(SignPrescriptionAction(prescriptionId: 6, result: result));
      final outcome = await result.future;
      expect(outcome.number, 'RX-6');
      expect(outcome.serverErrorAfterSave, isFalse);
    });

    test('a 500 after the script was signed is still a success', () async {
      repo.failAfterSave = _server500;
      final result = Completer<RxActionOutcome>();
      store.dispatch(SignPrescriptionAction(prescriptionId: 6, result: result));
      final outcome = await result.future;
      expect(outcome.serverErrorAfterSave, isTrue,
          reason: 'telling the doctor "failed" would make them sign again');
    });

    test('a sign that changed nothing fails with the error', () async {
      repo.failBeforeSave = const ApiException(
          message: 'Prescription has no medicines', statusCode: 400,
          kind: ApiErrorKind.http);
      final result = Completer<RxActionOutcome>();
      store.dispatch(SignPrescriptionAction(prescriptionId: 6, result: result));
      await expectLater(result.future, throwsA(isA<ApiException>()));
    });

    test('a 500 after a revoke was saved is still a success', () async {
      repo.status = PrescriptionStatus.signed;
      repo.failAfterSave = _server500;
      final result = Completer<RxActionOutcome>();
      store.dispatch(RevokePrescriptionAction(
          prescriptionId: 6, reason: 'Prescribed in error', result: result));
      final outcome = await result.future;
      expect(outcome.serverErrorAfterSave, isTrue);
    });
  });

  test('a medicine failing after the draft exists says how much was saved',
      () async {
    repo.failMedicineAt = 1;
    final result = Completer<int>();
    store.dispatch(CreatePrescriptionAction(
      appointmentId: 4,
      diagnosis: 'Acute bronchitis',
      medicines: [_med('Amoxicillin'), _med('Paracetamol'), _med('Ibuprofen')],
      result: result,
    ));
    try {
      await result.future;
      fail('expected a partial save');
    } on PartialPrescriptionException catch (e) {
      expect(e.saved, 1);
      expect(e.total, 3);
      expect(e.failedMedicine, 'Paracetamol');
    }
  });

  group('AppFeedback.describe', () {
    test('keeps the backend wording for a refusal', () {
      expect(
          AppFeedback.describe(const ApiException(
              message: 'Prescription already signed', statusCode: 400,
              kind: ApiErrorKind.http)),
          'Prescription already signed');
    });

    test('never shows a server crash or a raw exception', () {
      expect(AppFeedback.describe(_server500), isNot(contains('Email failed')));
      expect(AppFeedback.describe(StateError('x')), isNot(contains('StateError')));
    });

    test('tells the doctor to check their connection', () {
      expect(
          AppFeedback.describe(const ApiException(
              message: 'x', kind: ApiErrorKind.network)),
          contains('internet'));
    });
  });

  testWidgets('a success toast stays about 15 seconds, then goes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppFeedback.success(context, 'Saved it'),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Saved it'), findsOneWidget);

    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Saved it'), findsOneWidget, reason: 'still readable');

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Saved it'), findsNothing);
  });

  testWidgets('an error dialog stays until it is closed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => AppFeedback.error(context, 'It broke',
              title: 'Not saved'),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('It broke'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('It broke'), findsNothing);
  });
}

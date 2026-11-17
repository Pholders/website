import '../../../../app/app_state.dart';
import '../../dispensing_queue/data/models/claimed_prescription.dart';
import '../../orders/data/models/pharmacy_order.dart';

/// Where a claimed script is, from the pharmacy's side.
///
/// A patient claims a script for this pharmacy, which places an order. The
/// order carries the steps (accepted, preparing, ready, collected) and the
/// script itself is marked dispensed when the medicine is handed over.
enum ScriptStage {
  newScript('New'),
  accepted('Accepted'),
  inProgress('In-Progress'),
  ready('Ready'),
  collected('Collected'),
  dispensed('Dispensed'),
  closed('Closed');

  const ScriptStage(this.label);
  final String label;
}

/// One claimed script with the order its claim placed, if there is one.
class PharmacyScript {
  const PharmacyScript({
    required this.script,
    required this.dispensed,
    this.order,
  });

  final ClaimedPrescription script;
  final PharmacyOrder? order;

  /// The script has been marked dispensed (processed).
  final bool dispensed;

  int get id => script.id;

  ScriptStage get stage {
    if (dispensed) return ScriptStage.dispensed;
    return switch (order?.status) {
      null || OrderStatus.pending || OrderStatus.unknown => ScriptStage.newScript,
      OrderStatus.accepted ||
      OrderStatus.awaitingClaim ||
      OrderStatus.claimApproved =>
        ScriptStage.accepted,
      OrderStatus.preparing => ScriptStage.inProgress,
      OrderStatus.ready => ScriptStage.ready,
      OrderStatus.pickedUp => ScriptStage.collected,
      OrderStatus.claimRejected ||
      OrderStatus.cancelled ||
      OrderStatus.rejected =>
        ScriptStage.closed,
    };
  }

  /// The order has moved past "new". Every move after that sends the
  /// patient an update (the backend's order state machine does it, unless
  /// they muted order updates), so this is what the bell on the list means.
  bool get patientNotified {
    final status = order?.status;
    return status != null &&
        status != OrderStatus.pending &&
        status != OrderStatus.unknown;
  }

  /// "Ready for pickup" and so on: the last update the patient was sent.
  String? get lastUpdateSent => patientNotified ? order!.status.label : null;
}

/// Every claimed script at this pharmacy, newest claim first, each matched
/// to its order by prescription number.
List<PharmacyScript> pharmacyScripts(AppState state) {
  final ordersByNumber = <String, PharmacyOrder>{};
  for (final order in state.pharmacyOrdersState.orders) {
    final number = order.prescriptionNumber;
    if (number == null) continue;
    // A script can be claimed again after an order is closed: the live one
    // (not cancelled or rejected) is the one that counts.
    final existing = ordersByNumber[number];
    if (existing == null || (existing.status.isTerminal && !order.status.isTerminal)) {
      ordersByNumber[number] = order;
    }
  }

  final dispensing = state.dispensingState;
  final seen = <int>{};
  final scripts = <PharmacyScript>[];
  void add(ClaimedPrescription script, {required bool dispensed}) {
    if (!seen.add(script.id)) return;
    scripts.add(PharmacyScript(
      script: script,
      dispensed: dispensed,
      order: ordersByNumber[script.number],
    ));
  }

  for (final script in dispensing.awaiting) {
    add(script, dispensed: false);
  }
  for (final script in dispensing.dispensed) {
    add(script, dispensed: true);
  }

  scripts.sort((a, b) {
    final left = a.script.claimedAt;
    final right = b.script.claimedAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
  return scripts;
}

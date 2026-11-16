import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../dispensing_queue/data/models/claimed_prescription.dart';
import '../../dispensing_queue/redux/dispensing_actions.dart';
import '../../orders/data/models/pharmacy_order.dart';
import '../../orders/redux/orders_actions.dart';
import '../data/pharmacy_script.dart';
import 'pharmacy_prescriptions_page.dart' show dayMonth;
import 'script_widgets.dart';

/// One claimed script: who it is for, what to give them, how they pay and
/// whether they collect or want it delivered, and the step it is at.
///
/// Marking it dispensed here is the "processed" step. Accepting the order
/// and marking it ready happen on the order, which this page links to.
class PharmacyPrescriptionDetailPage extends StatelessWidget {
  const PharmacyPrescriptionDetailPage({
    super.key,
    required this.prescriptionId,
  });

  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(prescriptionId);
    return StoreConnector<AppState, _DetailViewModel>(
      distinct: true,
      converter: (store) => _DetailViewModel.fromStore(store, id),
      onInit: (store) {
        // Opened from a link or a refresh, nothing is in the store yet.
        if (!store.state.dispensingState.hasLoadedOnce) {
          store.dispatch(const LoadDispensingQueueAction());
        }
        if (!store.state.pharmacyOrdersState.hasLoadedOnce) {
          store.dispatch(const LoadPharmacyOrdersAction());
        }
      },
      builder: (context, vm) => Scaffold(
        backgroundColor: const Color(0xFFE8F8F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backLink(context),
              const SizedBox(height: 12),
              _body(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backLink(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.pharmacyPrescriptions),
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 18, color: scriptTeal),
            SizedBox(width: 6),
            Text(
              'Prescriptions',
              style: TextStyle(fontSize: 13, color: scriptTeal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, _DetailViewModel vm) {
    final row = vm.row;
    if (row == null) {
      if (!vm.loaded) {
        return vm.error != null
            ? _notice(vm.error!, retry: vm.onRefresh)
            : const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(color: scriptTeal)),
              );
      }
      return _notice(
          'This script is not among the ones claimed for this pharmacy.');
    }

    final script = row.script;
    final order = row.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(row),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _section('Patient', [
              _line('Name', script.patientName),
              _line('Email', script.patientEmail ?? '—'),
              _line('Phone', script.patientPhone ?? '—'),
            ]),
            _section('Collection and payment', [
              if (order == null)
                const Text(
                  'No order was placed with this claim.',
                  style: TextStyle(fontSize: 13, color: scriptTextMuted),
                )
              else ...[
                _line('Payment',
                    order.isMedicalAid ? 'Medical aid' : 'Self-pay'),
                _line('Getting it',
                    order.isDelivery ? 'Delivery' : 'Collect in store'),
                _line('Order', '${order.reference} · ${order.status.label}'),
                _line('Patient pays', order.dueLabel),
              ],
            ]),
          ],
        ),
        const SizedBox(height: 16),
        _medicines(script),
        const SizedBox(height: 16),
        _actions(context, row, vm),
      ],
    );
  }

  Widget _header(PharmacyScript row) {
    final claimed = row.script.claimedAt?.toLocal();
    final lastUpdate = row.lastUpdateSent;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.script.number,
                  key: const ValueKey('script-number'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scriptTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (claimed != null) 'Claimed ${dayMonth(claimed)}',
                    if (row.script.diagnosis != null) row.script.diagnosis!,
                  ].join(' · '),
                  style:
                      const TextStyle(fontSize: 13, color: scriptTextMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StageBadge(stage: row.stage),
              if (lastUpdate != null) ...[
                const SizedBox(height: 8),
                Row(
                  key: const ValueKey('patient-notified'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PatientNotifiedBell(lastUpdate: lastUpdate),
                    const SizedBox(width: 6),
                    Text(
                      'Patient notified: $lastUpdate',
                      style: const TextStyle(
                          fontSize: 12, color: scriptTextMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicines(ClaimedPrescription script) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicines',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scriptTextDark,
            ),
          ),
          const SizedBox(height: 10),
          if (script.medicines.isEmpty)
            const Text('No medicines listed.',
                style: TextStyle(fontSize: 13, color: scriptTextMuted))
          else
            for (final medicine in script.medicines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.medication_outlined,
                          size: 18, color: scriptTeal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scriptTextDark,
                            ),
                          ),
                          if (medicine.detail.isNotEmpty)
                            Text(medicine.detail,
                                style: const TextStyle(
                                    fontSize: 12, color: scriptTextMuted)),
                          if ((medicine.instructions ?? '').trim().isNotEmpty)
                            Text(medicine.instructions!,
                                style: const TextStyle(
                                    fontSize: 12, color: scriptTextMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, PharmacyScript row, _DetailViewModel vm) {
    final order = row.order;
    final busy = vm.busy && !row.dispensed;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (row.dispensed)
          const Row(
            key: ValueKey('script-dispensed'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text('Dispensed',
                  style: TextStyle(fontSize: 14, color: Color(0xFF16A34A))),
            ],
          )
        else
          FilledButton.icon(
            key: const ValueKey('script-dispense'),
            style: FilledButton.styleFrom(backgroundColor: scriptTeal),
            onPressed: busy ? null : () => _confirmDispense(context, row, vm),
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(busy ? 'Working…' : 'Mark as dispensed'),
          ),
        if (order != null)
          OutlinedButton(
            key: const ValueKey('script-open-order'),
            onPressed: () => context.go(AppRoutes.pharmacyOrderDetail
                .replaceFirst(':orderId', '${order.id}')),
            child: Text(_orderActionLabel(order)),
          ),
        if (vm.dispenseError != null)
          Text(
            vm.dispenseError!,
            key: const ValueKey('script-error'),
            style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
          ),
      ],
    );
  }

  String _orderActionLabel(PharmacyOrder order) => switch (order.status) {
        OrderStatus.pending => 'Accept or reject the order',
        OrderStatus.accepted ||
        OrderStatus.claimApproved ||
        OrderStatus.preparing =>
          'Update the order',
        _ => 'Open the order',
      };

  void _confirmDispense(
      BuildContext context, PharmacyScript row, _DetailViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark this script as dispensed?'),
        content: Text(
          'Confirm ${row.script.patientName} has been given '
          '${row.script.medicineSummary}. The prescribing doctor is told it '
          'was dispensed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('script-dispense-confirm'),
            style: FilledButton.styleFrom(backgroundColor: scriptTeal),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.onDispense(row.id);
            },
            child: const Text('Dispensed'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 520),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scriptTextDark,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: scriptTextMuted)),
            ),
            Expanded(
              child: Text(value,
                  style:
                      const TextStyle(fontSize: 13, color: scriptTextDark)),
            ),
          ],
        ),
      );

  Widget _card({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        color: Colors.white,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: scriptAqua),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice(String text, {VoidCallback? retry}) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: const TextStyle(fontSize: 14, color: scriptTextMuted)),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Try again')),
          ],
        ),
      );
}

class _DetailViewModel {
  _DetailViewModel({
    required this.row,
    required this.loaded,
    required this.busy,
    required this.error,
    required this.dispenseError,
    required this.onRefresh,
    required this.onDispense,
  });

  factory _DetailViewModel.fromStore(Store<AppState> store, int? id) {
    final dispensing = store.state.dispensingState;
    PharmacyScript? row;
    if (id != null) {
      for (final candidate in pharmacyScripts(store.state)) {
        if (candidate.id == id) row = candidate;
      }
    }
    return _DetailViewModel(
      row: row,
      loaded: dispensing.hasLoadedOnce,
      busy: id != null && dispensing.busyIds.contains(id),
      error: dispensing.errorMessage,
      // A failed dispense leaves the error on the slice; show it here only
      // while the script is still waiting, which it then still is.
      dispenseError: row != null && !row.dispensed ? dispensing.errorMessage : null,
      onRefresh: () {
        store.dispatch(const LoadDispensingQueueAction());
        store.dispatch(const LoadPharmacyOrdersAction());
      },
      onDispense: (prescriptionId) => store
          .dispatch(DispensePrescriptionAction(prescriptionId: prescriptionId)),
    );
  }

  final PharmacyScript? row;
  final bool loaded;
  final bool busy;
  final String? error;
  final String? dispenseError;
  final VoidCallback onRefresh;
  final void Function(int prescriptionId) onDispense;

  @override
  bool operator ==(Object other) =>
      other is _DetailViewModel &&
      other.row?.id == row?.id &&
      other.row?.stage == row?.stage &&
      other.row?.patientNotified == row?.patientNotified &&
      identical(other.row?.script, row?.script) &&
      identical(other.row?.order, row?.order) &&
      other.loaded == loaded &&
      other.busy == busy &&
      other.error == error &&
      other.dispenseError == dispenseError;

  @override
  int get hashCode =>
      Object.hash(row?.id, row?.stage, loaded, busy, error, dispenseError);
}

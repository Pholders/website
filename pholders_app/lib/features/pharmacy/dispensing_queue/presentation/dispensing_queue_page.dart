import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../data/models/claimed_prescription.dart';
import '../redux/dispensing_actions.dart';

/// Dispensing Queue — scripts patients have sent to this pharmacy.
///
/// A prescription arrives here when the patient claims it, and leaves when it
/// is dispensed. Those are the only two states the backend keeps, so the
/// filters are Awaiting and Dispensed rather than a longer pipeline.
class DispensingQueuePage extends StatefulWidget {
  const DispensingQueuePage({super.key});

  @override
  State<DispensingQueuePage> createState() => _DispensingQueuePageState();
}

class _DispensingQueuePageState extends State<DispensingQueuePage> {
  int _selectedTab = 0;

  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  final List<String> _tabs = ['All', 'Awaiting', 'Dispensed'];

  List<_Row> _rows(_QueueViewModel vm) {
    final awaiting = vm.awaiting.map((p) => _Row(p, dispensed: false));
    final dispensed = vm.dispensed.map((p) => _Row(p, dispensed: true));
    switch (_selectedTab) {
      case 1:
        return awaiting.toList();
      case 2:
        return dispensed.toList();
      default:
        return [...awaiting, ...dispensed];
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _QueueViewModel>(
      converter: _QueueViewModel.fromStore,
      onInit: (store) => store.dispatch(const LoadDispensingQueueAction()),
      builder: (context, vm) {
        return Scaffold(
          backgroundColor: const Color(0xFFE8F8F8),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(vm),
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 4),
                Expanded(child: _buildTable(vm)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(_QueueViewModel vm) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dispensing Queue', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textDark)),
              SizedBox(height: 4),
              Text('Scripts patients have sent to this pharmacy', style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
        Text('${vm.awaiting.length} in queue', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted)),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final isActive = _selectedTab == i;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => setState(() => _selectedTab = i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_tabs[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : _textMuted)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTable(_QueueViewModel vm) {
    final data = _rows(vm);
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 3, child: Text('Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        // The claimed-prescriptions endpoint carries no
                        // prescriber, and a pharmacy quotes the reference
                        // anyway when querying a script.
                        Expanded(flex: 3, child: Text('Reference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Claimed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                      ],
                    ),
                  ),
                  Expanded(child: _buildBody(vm, data)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_QueueViewModel vm, List<_Row> data) {
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _teal),
            SizedBox(height: 14),
            // The API sleeps when idle, so a first load can take ~30s.
            Text('Loading the queue...', style: TextStyle(fontSize: 13, color: _textMuted)),
          ],
        ),
      );
    }

    if (vm.errorMessage != null && data.isEmpty) {
      return _message(
        icon: Icons.cloud_off_outlined,
        title: vm.errorMessage!,
        action: TextButton(onPressed: vm.onRefresh, child: const Text('Try again')),
      );
    }

    if (data.isEmpty) {
      return _message(
        icon: Icons.inbox_outlined,
        title: _selectedTab == 2
            ? 'Nothing has been dispensed yet.'
            : 'No scripts waiting.\nA prescription appears here once a patient sends it to you.',
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, i) => _buildRow(vm, data[i]),
    );
  }

  Widget _buildRow(_QueueViewModel vm, _Row row) {
    final item = row.prescription;
    final isBusy = vm.busyIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x33309CA3), border: Border.all(color: _teal, width: 1)), child: const Icon(Icons.person, size: 14, color: _teal)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark), overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: 3, child: Text(item.medicineSummary, style: const TextStyle(fontSize: 13, color: _textDark), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(item.number, style: const TextStyle(fontSize: 12, color: _textMuted), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(item.claimedTime, style: const TextStyle(fontSize: 13, color: _textMuted))),
          Expanded(flex: 2, child: _StatusDot(status: row.dispensed ? 'Dispensed' : 'Awaiting')),
          Expanded(
            flex: 2,
            child: row.dispensed
                ? const Text('—', style: TextStyle(fontSize: 13, color: _textMuted))
                : InkWell(
                    onTap: isBusy ? null : () => _confirmDispense(vm, item),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isBusy ? const Color(0xFFB9E4E8) : const Color(0xFF6DD0D8),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: Text(isBusy ? 'Working...' : 'Dispense', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _message({required IconData icon, required String title, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _textMuted)),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  /// Dispensing cannot be undone from here, so it is confirmed first and the
  /// medicines are listed to check against what is being handed over.
  void _confirmDispense(_QueueViewModel vm, ClaimedPrescription item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dispense this prescription?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.patientName} — ${item.number}', style: const TextStyle(fontSize: 14, color: _textDark)),
            const SizedBox(height: 10),
            if (item.medicines.isEmpty)
              const Text('No medicines are listed on this script.', style: TextStyle(fontSize: 13, color: _textMuted))
            else
              ...item.medicines.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${m.name}${m.detail.isEmpty ? '' : ' — ${m.detail}'}', style: const TextStyle(fontSize: 13, color: _textMuted)),
                ),
              ),
            const SizedBox(height: 10),
            const Text('This marks the script as collected and cannot be undone.', style: TextStyle(fontSize: 12, color: _textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.onDispense(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Dispense'),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'Awaiting': return const Color(0xFFF97316);
      case 'Dispensed': return const Color(0xFF34D399);
      default: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _color)),
      const SizedBox(width: 6),
      Flexible(child: Text(status, style: TextStyle(fontSize: 12, color: _color), overflow: TextOverflow.ellipsis)),
    ]);
  }
}

/// One table row: a prescription, and which side of the queue it sits on.
class _Row {
  const _Row(this.prescription, {required this.dispensed});
  final ClaimedPrescription prescription;
  final bool dispensed;
}

class _QueueViewModel {
  const _QueueViewModel({
    required this.awaiting,
    required this.dispensed,
    required this.isLoading,
    required this.hasLoadedOnce,
    required this.busyIds,
    required this.onDispense,
    required this.onRefresh,
    this.errorMessage,
  });

  factory _QueueViewModel.fromStore(Store<AppState> store) {
    final state = store.state.dispensingState;
    return _QueueViewModel(
      awaiting: state.awaiting,
      dispensed: state.dispensed,
      isLoading: state.isLoading,
      hasLoadedOnce: state.hasLoadedOnce,
      busyIds: state.busyIds,
      errorMessage: state.errorMessage,
      onDispense: (id) =>
          store.dispatch(DispensePrescriptionAction(prescriptionId: id)),
      onRefresh: () => store.dispatch(const LoadDispensingQueueAction()),
    );
  }

  final List<ClaimedPrescription> awaiting;
  final List<ClaimedPrescription> dispensed;
  final bool isLoading;
  final bool hasLoadedOnce;
  final Set<int> busyIds;
  final String? errorMessage;
  final void Function(int prescriptionId) onDispense;
  final VoidCallback onRefresh;
}

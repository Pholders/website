import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../dispensing_queue/redux/dispensing_actions.dart';
import '../../orders/redux/orders_actions.dart';
import '../data/pharmacy_script.dart';
import 'script_widgets.dart';

/// Every script patients have claimed for this pharmacy, with where each one
/// is: the order its claim placed sets the step, and dispensing closes it.
class PharmacyPrescriptionsPage extends StatefulWidget {
  const PharmacyPrescriptionsPage({super.key});

  @override
  State<PharmacyPrescriptionsPage> createState() =>
      _PharmacyPrescriptionsPageState();
}

class _PharmacyPrescriptionsPageState extends State<PharmacyPrescriptionsPage> {
  /// null is All.
  ScriptStage? _tab;

  static const _tabs = <ScriptStage?>[
    null,
    ScriptStage.newScript,
    ScriptStage.accepted,
    ScriptStage.inProgress,
    ScriptStage.ready,
    ScriptStage.dispensed,
  ];

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ListViewModel>(
      distinct: true,
      converter: _ListViewModel.fromStore,
      onInit: (store) {
        store.dispatch(const LoadDispensingQueueAction());
        store.dispatch(const LoadPharmacyOrdersAction());
      },
      builder: (context, vm) {
        final rows = _tab == null
            ? vm.scripts
            : vm.scripts.where((s) => s.stage == _tab).toList();
        return Scaffold(
          backgroundColor: const Color(0xFFE8F8F8),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(vm),
                const SizedBox(height: 16),
                _buildTabs(vm),
                const SizedBox(height: 4),
                Expanded(child: _buildTable(vm, rows)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(_ListViewModel vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescriptions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: scriptTextDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Scripts patients have claimed for this pharmacy',
                style: TextStyle(fontSize: 14, color: scriptTextMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: vm.loading ? null : vm.onRefresh,
          icon: const Icon(Icons.refresh, color: scriptTextMuted),
        ),
      ],
    );
  }

  Widget _buildTabs(_ListViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tab in _tabs)
                InkWell(
                  key: ValueKey('scripts-tab-${tab?.name ?? 'all'}'),
                  onTap: () => setState(() => _tab = tab),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _tab == tab ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tab?.label ?? 'All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _tab == tab ? Colors.white : scriptTextMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          'Total: ${vm.loaded ? vm.scripts.length : '–'}',
          key: const ValueKey('scripts-total'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: scriptTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTable(_ListViewModel vm, List<PharmacyScript> rows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(width: 11, color: scriptAqua),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(constraints.maxWidth, 860),
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        const _HeaderRow(),
                        Expanded(child: _buildRows(vm, rows)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows(_ListViewModel vm, List<PharmacyScript> rows) {
    if (!vm.loaded) {
      if (vm.error != null) return _message(vm.error!, retry: vm.onRefresh);
      return const Center(child: CircularProgressIndicator(color: scriptTeal));
    }
    if (rows.isEmpty) {
      return _message(_tab == null
          ? 'No scripts yet. They appear here when a patient claims one for this pharmacy.'
          : 'Nothing is ${_tab!.label.toLowerCase()} right now.');
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => _ScriptRow(row: rows[index]),
    );
  }

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: scriptTextMuted),
              ),
              if (retry != null)
                TextButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _ColHeader('Patient')),
          Expanded(flex: 3, child: _ColHeader('Reference')),
          Expanded(flex: 3, child: _ColHeader('Medication')),
          Expanded(flex: 2, child: _ColHeader('Claimed')),
          Expanded(flex: 2, child: _ColHeader('Status')),
          Expanded(flex: 2, child: _ColHeader('Action')),
        ],
      ),
    );
  }
}

class _ScriptRow extends StatelessWidget {
  const _ScriptRow({required this.row});
  final PharmacyScript row;

  @override
  Widget build(BuildContext context) {
    void open() => context.go(AppRoutes.pharmacyPrescriptionDetail
        .replaceFirst(':prescriptionId', '${row.id}'));
    final claimed = row.script.claimedAt?.toLocal();
    final lastUpdate = row.lastUpdateSent;
    return InkWell(
      key: ValueKey('script-row-${row.id}'),
      onTap: open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x33309CA3),
                      border: Border.all(color: scriptTeal, width: 1),
                    ),
                    child:
                        const Icon(Icons.person, size: 14, color: scriptTeal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.script.patientName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scriptTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                row.script.number,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: scriptTextMuted),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                row.script.medicineSummary,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: scriptTextDark),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                claimed == null ? '—' : dayMonth(claimed),
                style: const TextStyle(fontSize: 13, color: scriptTextMuted),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Flexible(child: StageBadge(stage: row.stage)),
                  if (lastUpdate != null) ...[
                    const SizedBox(width: 6),
                    PatientNotifiedBell(lastUpdate: lastUpdate),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: open,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: scriptAqua,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1)),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: scriptTextMuted,
      ),
    );
  }
}

class _ListViewModel {
  _ListViewModel({
    required this.scripts,
    required this.loaded,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  factory _ListViewModel.fromStore(Store<AppState> store) {
    final dispensing = store.state.dispensingState;
    final orders = store.state.pharmacyOrdersState;
    return _ListViewModel(
      scripts: pharmacyScripts(store.state),
      // The scripts are the list; orders only colour it in, so the list
      // shows as soon as the scripts are in.
      loaded: dispensing.hasLoadedOnce,
      loading: dispensing.isLoading || orders.isLoading,
      error: dispensing.errorMessage,
      onRefresh: () {
        store.dispatch(const LoadDispensingQueueAction());
        store.dispatch(const LoadPharmacyOrdersAction());
      },
    );
  }

  final List<PharmacyScript> scripts;
  final bool loaded;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  bool operator ==(Object other) =>
      other is _ListViewModel &&
      other.loaded == loaded &&
      other.loading == loading &&
      other.error == error &&
      _sameScripts(other.scripts, scripts);

  static bool _sameScripts(List<PharmacyScript> a, List<PharmacyScript> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].stage != b[i].stage ||
          a[i].patientNotified != b[i].patientNotified) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(loaded, loading, error, scripts.length);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "16 Nov".
String dayMonth(DateTime day) => '${day.day} ${_months[day.month - 1]}';

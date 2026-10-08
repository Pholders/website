import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../data/models/pharmacy_order.dart';
import '../redux/orders_actions.dart';

/// Orders — what patients have asked this pharmacy to fill.
///
/// The tabs follow the backend's own state machine. There is no
/// "out for delivery" status, only a fulfilment type, so that tab is gone
/// rather than left permanently empty.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int _selectedTab = 0;

  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _pendingOrange = Color(0xFFFBBF24);
  static const Color _processingBlue = Color(0xFF3B82F6);
  static const Color _readyGreen = Color(0xFF34D399);
  static const Color _doneGrey = Color(0xFF9CA3AF);

  final List<String> _tabs = [
    'All',
    'New',
    'Processing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

  /// Which backend statuses each tab gathers.
  static const Map<String, List<OrderStatus>> _tabStatuses = {
    'New': [OrderStatus.pending],
    'Processing': [
      OrderStatus.accepted,
      OrderStatus.awaitingClaim,
      OrderStatus.claimApproved,
      OrderStatus.claimRejected,
      OrderStatus.preparing,
    ],
    'Ready': [OrderStatus.ready],
    'Completed': [OrderStatus.pickedUp],
    'Cancelled': [OrderStatus.cancelled, OrderStatus.rejected],
  };

  List<PharmacyOrder> _filtered(List<PharmacyOrder> orders) {
    final tab = _tabs[_selectedTab];
    if (tab == 'All') return orders;
    final wanted = _tabStatuses[tab] ?? const [];
    return orders.where((o) => wanted.contains(o.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _OrdersViewModel>(
      converter: _OrdersViewModel.fromStore,
      onInit: (store) => store.dispatch(const LoadPharmacyOrdersAction()),
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

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(_OrdersViewModel vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Orders patients have placed with this pharmacy',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        _buildRefreshButton(vm),
      ],
    );
  }

  /// Refresh, not "New Order": only a patient can create one, so a button
  /// here would offer something the pharmacy role cannot do.
  Widget _buildRefreshButton(_OrdersViewModel vm) {
    return InkWell(
      onTap: vm.isLoading ? null : vm.onRefresh,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: vm.isLoading ? const Color(0xFFB9E4E8) : _teal,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              vm.isLoading ? 'Refreshing' : 'Refresh',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final isActive = _selectedTab == index;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => setState(() => _selectedTab = index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : _textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Table ───────────────────────────────────────────────────────────────
  Widget _buildTable(_OrdersViewModel vm) {
    final data = _filtered(vm.orders);
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
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: _ColHeader('Order ID')),
                        Expanded(flex: 3, child: _ColHeader('Patient')),
                        // The queue carries the script reference, not an item
                        // count — a pharmacy pulls the script by reference.
                        Expanded(flex: 3, child: _ColHeader('Script')),
                        Expanded(flex: 2, child: _ColHeader('Total')),
                        Expanded(flex: 2, child: _ColHeader('Payment')),
                        Expanded(flex: 2, child: _ColHeader('Status')),
                        Expanded(flex: 3, child: _ColHeader('Action')),
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

  Widget _buildBody(_OrdersViewModel vm, List<PharmacyOrder> data) {
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _teal),
            SizedBox(height: 14),
            Text('Loading orders...',
                style: TextStyle(fontSize: 13, color: _textMuted)),
          ],
        ),
      );
    }

    if (vm.errorMessage != null && data.isEmpty) {
      return _message(
        icon: Icons.cloud_off_outlined,
        title: vm.errorMessage!,
        action:
            TextButton(onPressed: vm.onRefresh, child: const Text('Try again')),
      );
    }

    if (data.isEmpty) {
      return _message(
        icon: Icons.receipt_long_outlined,
        title: _selectedTab == 0
            ? 'No orders yet.\nAn order appears here when a patient asks you to fill a script.'
            : 'Nothing in ${_tabs[_selectedTab]}.',
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) => _buildRow(vm, data[index]),
    );
  }

  Widget _buildRow(_OrdersViewModel vm, PharmacyOrder order) {
    final isBusy = vm.busyIds.contains(order.id);
    return InkWell(
      onTap: () => context.go('/pharmacy/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                order.reference,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                order.patientName ?? 'Unknown patient',
                style: const TextStyle(fontSize: 13, color: _textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                order.prescriptionNumber ?? '—',
                style: const TextStyle(fontSize: 12, color: _textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.totalLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _Dot(
                colour: order.isMedicalAid ? _processingBlue : _pendingOrange,
                label: order.isMedicalAid ? 'Medical aid' : 'Self-pay',
              ),
            ),
            Expanded(
              flex: 2,
              child: _Dot(
                colour: _statusColour(order.status),
                label: order.status.label,
              ),
            ),
            Expanded(flex: 3, child: _buildAction(vm, order, isBusy)),
          ],
        ),
      ),
    );
  }

  static Color _statusColour(OrderStatus status) {
    if (status == OrderStatus.pending) return _pendingOrange;
    if (status == OrderStatus.ready) return _readyGreen;
    if (status.isTerminal) return _doneGrey;
    return _processingBlue;
  }

  /// A new order is accepted or declined; anything else moves one step along
  /// the backend's state machine. Nothing is offered when the order is
  /// finished or waiting on a medical aid claim.
  Widget _buildAction(_OrdersViewModel vm, PharmacyOrder order, bool isBusy) {
    if (isBusy) return const _Pill(label: 'Working...', enabled: false);

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          _Pill(label: 'Accept', onTap: () => _confirmAccept(vm, order)),
          const SizedBox(width: 6),
          _Pill(
            label: 'Decline',
            danger: true,
            onTap: () => _confirmReject(vm, order),
          ),
        ],
      );
    }

    final next = order.nextStatus;
    if (next == null) {
      return Text(
        order.status == OrderStatus.awaitingClaim
            ? 'Awaiting the medical aid'
            : '—',
        style: const TextStyle(fontSize: 12, color: _textMuted),
        overflow: TextOverflow.ellipsis,
      );
    }

    return _Pill(
      label: switch (next) {
        OrderStatus.preparing => 'Start preparing',
        OrderStatus.ready => 'Mark ready',
        OrderStatus.pickedUp => 'Collected',
        _ => next.label,
      },
      onTap: () => vm.onSetStatus(order.id, next),
    );
  }

  Widget _message({required IconData icon, required String title, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: _doneGrey),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  /// Accepting can carry a price. A medical aid order may be accepted without
  /// one, because the claim decides what the patient owes.
  void _confirmAccept(_OrdersViewModel vm, PharmacyOrder order) {
    final totalController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept this order?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.reference} — ${order.patientName ?? 'Unknown patient'}',
              style: const TextStyle(fontSize: 14, color: _textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total (optional)',
                prefixText: 'R ',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.isMedicalAid
                  ? 'A medical aid order can be accepted without a price — the claim decides what the patient owes.'
                  : 'Leave blank to quote later.',
              style: const TextStyle(fontSize: 12, color: _textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final total = double.tryParse(totalController.text.trim());
              Navigator.pop(ctx);
              vm.onAccept(order.id, total);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  /// Declining needs a reason: it is what the patient is told.
  void _confirmReject(_OrdersViewModel vm, PharmacyOrder order) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final reason = reasonController.text.trim();
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Decline this order?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.reference} — ${order.patientName ?? 'Unknown patient'}',
                  style: const TextStyle(fontSize: 14, color: _textDark),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Out of stock',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The patient sees this, so say what they should do next.',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _textMuted)),
              ),
              ElevatedButton(
                onPressed: reason.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        vm.onReject(order.id, reason);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Decline'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.colour, required this.label});
  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.onTap,
    this.danger = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isOn = enabled && onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: !isOn
              ? const Color(0xFFE5E7EB)
              : danger
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFF6DD0D8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: !isOn
                ? const Color(0xFF6B7280)
                : danger
                    ? const Color(0xFFB91C1C)
                    : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OrdersViewModel {
  const _OrdersViewModel({
    required this.orders,
    required this.isLoading,
    required this.hasLoadedOnce,
    required this.busyIds,
    required this.onAccept,
    required this.onReject,
    required this.onSetStatus,
    required this.onRefresh,
    this.errorMessage,
  });

  factory _OrdersViewModel.fromStore(Store<AppState> store) {
    final state = store.state.pharmacyOrdersState;
    return _OrdersViewModel(
      orders: state.orders,
      isLoading: state.isLoading,
      hasLoadedOnce: state.hasLoadedOnce,
      busyIds: state.busyIds,
      errorMessage: state.errorMessage,
      onAccept: (id, total) => store.dispatch(
        AcceptOrderAction(orderId: id, totalAmount: total),
      ),
      onReject: (id, reason) =>
          store.dispatch(RejectOrderAction(orderId: id, reason: reason)),
      onSetStatus: (id, status) =>
          store.dispatch(SetOrderStatusAction(orderId: id, status: status)),
      onRefresh: () => store.dispatch(const LoadPharmacyOrdersAction()),
    );
  }

  final List<PharmacyOrder> orders;
  final bool isLoading;
  final bool hasLoadedOnce;
  final Set<int> busyIds;
  final String? errorMessage;
  final void Function(int orderId, double? totalAmount) onAccept;
  final void Function(int orderId, String reason) onReject;
  final void Function(int orderId, OrderStatus status) onSetStatus;
  final VoidCallback onRefresh;
}

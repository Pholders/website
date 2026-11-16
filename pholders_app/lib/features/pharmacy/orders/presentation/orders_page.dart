import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../data/models/pharmacy_order.dart';
import '../redux/orders_actions.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _pendingOrange = Color(0xFFFBBF24);
  static const Color _processingBlue = Color(0xFF3B82F6);
  static const Color _readyGreen = Color(0xFF34D399);
  static const Color _doneGrey = Color(0xFF9CA3AF);

  static const List<String> _tabs = [
    'All',
    'New',
    'Processing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

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

  int _selectedTab = 0;

  List<PharmacyOrder> _filtered(List<PharmacyOrder> orders) {
    final tab = _tabs[_selectedTab];
    if (tab == 'All') return orders;
    final statuses = _tabStatuses[tab] ?? const [];
    return orders.where((order) => statuses.contains(order.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _OrdersViewModel>(
      converter: _OrdersViewModel.fromStore,
      onInit: (store) => store.dispatch(const LoadPharmacyOrdersAction()),
      builder: (context, vm) => Scaffold(
        backgroundColor: const Color(0xFFE8F8F8),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(vm),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTabs(),
              ),
              const SizedBox(height: 4),
              Expanded(child: _buildTable(vm)),
            ],
          ),
        ),
      ),
    );
  }

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
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: vm.isLoading ? null : vm.onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(vm.isLoading ? 'Refreshing' : 'Refresh'),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final active = _selectedTab == index;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => setState(() => _selectedTab = index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : _textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTable(_OrdersViewModel vm) {
    final orders = _filtered(vm.orders);
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (vm.errorMessage != null && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: vm.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (orders.isEmpty) {
      return Center(
        child: Text(
          _selectedTab == 0
              ? 'No orders yet. An order appears here when a patient asks you to fill a script.'
              : 'Nothing in ${_tabs[_selectedTab]}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textMuted),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1120,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: _ColumnHeader('Order ID')),
                      Expanded(flex: 3, child: _ColumnHeader('Patient')),
                      Expanded(flex: 3, child: _ColumnHeader('Script')),
                      Expanded(flex: 2, child: _ColumnHeader('Total')),
                      Expanded(flex: 2, child: _ColumnHeader('Payment')),
                      Expanded(flex: 2, child: _ColumnHeader('Status')),
                      Expanded(flex: 3, child: _ColumnHeader('Action')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildRow(vm, orders[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(_OrdersViewModel vm, PharmacyOrder order) {
    final busy = vm.busyIds.contains(order.id);
    return InkWell(
      onTap: () => context.go('/pharmacy/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(order.reference)),
            Expanded(
              flex: 3,
              child: Text(
                order.patientName ?? 'Unknown patient',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                order.prescriptionNumber ?? 'Not provided',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(flex: 2, child: Text(order.totalLabel)),
            Expanded(
              flex: 2,
              child: _StatusDot(
                color: order.isMedicalAid ? _processingBlue : _pendingOrange,
                label: order.isMedicalAid ? 'Medical aid' : 'Self-pay',
              ),
            ),
            Expanded(
              flex: 2,
              child: _StatusDot(
                color: _statusColour(order.status),
                label: order.status.label,
              ),
            ),
            Expanded(flex: 3, child: _buildAction(vm, order, busy)),
          ],
        ),
      ),
    );
  }

  Color _statusColour(OrderStatus status) {
    if (status == OrderStatus.pending) return _pendingOrange;
    if (status == OrderStatus.ready) return _readyGreen;
    if (status.isTerminal) return _doneGrey;
    return _processingBlue;
  }

  Widget _buildAction(_OrdersViewModel vm, PharmacyOrder order, bool busy) {
    if (busy) return const _ActionPill(label: 'Working...', enabled: false);
    if (order.status == OrderStatus.pending) {
      return Wrap(
        spacing: 6,
        children: [
          _ActionPill(label: 'Accept', onTap: () => _confirmAccept(vm, order)),
          _ActionPill(
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
            : 'No action',
        style: const TextStyle(fontSize: 12, color: _textMuted),
      );
    }
    return _ActionPill(
      label: switch (next) {
        OrderStatus.preparing => 'Start preparing',
        OrderStatus.ready => 'Mark ready',
        OrderStatus.pickedUp => 'Collected',
        _ => next.label,
      },
      onTap: () => vm.onSetStatus(order.id, next),
    );
  }

  Future<void> _confirmAccept(
    _OrdersViewModel vm,
    PharmacyOrder order,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept this order?'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Total (optional)',
            prefixText: 'R ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final total = value.isEmpty ? null : double.tryParse(value);
    if (value.isNotEmpty && total == null) {
      _showMessage('Enter a valid total amount.');
      return;
    }
    vm.onAccept(order.id, total);
  }

  Future<void> _confirmReject(
    _OrdersViewModel vm,
    PharmacyOrder order,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline this order?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    if (reason.isEmpty) {
      _showMessage('Enter a reason for declining the order.');
      return;
    }
    vm.onReject(order.id, reason);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      );
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
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
    final active = enabled && onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: !active
              ? const Color(0xFFE5E7EB)
              : danger
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFF6DD0D8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: !active
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

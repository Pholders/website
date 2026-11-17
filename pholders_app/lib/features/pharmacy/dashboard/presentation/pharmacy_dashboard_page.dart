import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/utils/greeting.dart';
import '../../dispensing_queue/data/models/claimed_prescription.dart';
import '../../dispensing_queue/redux/dispensing_actions.dart';
import '../../orders/data/models/pharmacy_order.dart';
import '../../orders/redux/orders_actions.dart';

/// Pharmacy Dashboard matching the Figma design (node 1610:357).
///
/// Everything on it comes from the server, through the same store slices
/// the Orders and Dispensing Queue pages use, so the counts here and the
/// lists there always agree:
/// 1. Date and greeting
/// 2. Counts: new orders, scripts to dispense, ready for pickup, dispensed
/// 3. Orders still in progress, newest first
/// 4. Incoming prescriptions: claimed scripts not yet dispensed
class PharmacyDashboardPage extends StatelessWidget {
  const PharmacyDashboardPage({super.key, this.today});

  /// Fixed by tests so the date line does not depend on the clock.
  final DateTime? today;

  // ─── Colors from Figma ───────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF000000);
  static const Color _textMuted = Color(0x66000000); // rgba(0,0,0,0.4)
  static const Color _textLight = Color(0x40000000); // rgba(0,0,0,0.25)
  static const Color _sectionBorder = Color(0xFF6DD0D8);
  static const Color _orangeAccent = Color(0xA8FC9300); // rgba(252,147,0,0.66)
  static const Color _statusDotOrange = Color(0xA8FC9300);
  static const Color _bgLight = Color(0x33309CA3); // rgba(109,208,216,0.2)

  /// How many rows each section shows before pointing to the full page.
  static const _previewRows = 5;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _DashboardViewModel>(
      distinct: true,
      converter: _DashboardViewModel.fromStore,
      onInit: (store) {
        store.dispatch(const LoadPharmacyOrdersAction());
        store.dispatch(const LoadDispensingQueueAction());
      },
      builder: (context, vm) => Scaffold(
        backgroundColor: const Color(0xFFE8F8F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateAndGreeting(vm),
              const SizedBox(height: 10),
              _buildStatsSection(vm),
              const SizedBox(height: 10),
              _buildOrdersSection(context, vm),
              const SizedBox(height: 10),
              _buildIncomingPrescriptionsSection(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Date + Greeting ─────────────────────────────────────────────────────
  Widget _buildDateAndGreeting(_DashboardViewModel vm) {
    final name = vm.userName?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              longDate(today ?? DateTime.now()),
              style: const TextStyle(
                fontSize: 11,
                color: _textMuted,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              key: const ValueKey('dashboard-refresh'),
              onTap: vm.loading ? null : vm.onRefresh,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: vm.loading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: _textMuted),
                      )
                    : const Icon(Icons.refresh, size: 14, color: _textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${timeOfDayGreeting()} ${name.isEmpty ? 'there' : name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textDark,
            fontFamily: 'Sora',
          ),
        ),
        if (vm.error != null) ...[
          const SizedBox(height: 6),
          Text(
            vm.error!,
            key: const ValueKey('dashboard-error'),
            style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }

  // ─── Stats Section ───────────────────────────────────────────────────────
  Widget _buildStatsSection(_DashboardViewModel vm) {
    String count(int value, bool loaded) => loaded ? '$value' : '–';
    return _card(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'New Orders',
              count(vm.newOrders, vm.ordersLoaded),
              'Waiting to be accepted',
              'assets/black-pill-icon.png',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              'Pending Dispensing',
              count(vm.awaiting.length, vm.scriptsLoaded),
              'Claimed, not yet dispensed',
              'assets/dispensing-icon.png',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              'Ready for Pickup',
              count(vm.readyForPickup, vm.ordersLoaded),
              'Awaiting collection',
              'assets/pickup-icon.png',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              'Completed',
              count(vm.dispensedCount, vm.scriptsLoaded),
              'Scripts dispensed',
              'assets/completed-icon.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, String subtitle, String iconAsset) {
    return Column(
      key: ValueKey('dashboard-stat-$label'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 28,
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(iconAsset, width: 18, height: 18),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: _textDark,
            fontFamily: 'Sora',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textDark,
            fontFamily: 'Sora',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 7,
            color: _textMuted,
            fontFamily: 'Sora',
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ─── Orders Section ──────────────────────────────────────────────────────
  Widget _buildOrdersSection(BuildContext context, _DashboardViewModel vm) {
    final orders = vm.openOrders.take(_previewRows).toList();
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: 'assets/orders-icon.png',
            title: 'Orders',
            trailing: _seeAll(context, AppRoutes.pharmacyOrders,
                key: 'dashboard-all-orders'),
          ),
          const SizedBox(height: 12),
          if (!vm.ordersLoaded)
            _placeholder('Loading orders…')
          else if (orders.isEmpty)
            _placeholder('No orders in progress.')
          else
            for (final (i, order) in orders.indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              _buildOrderTimelineItem(context, order),
            ],
        ],
      ),
    );
  }

  Widget _buildOrderTimelineItem(BuildContext context, PharmacyOrder order) {
    final accent = switch (order.status) {
      OrderStatus.pending => _orangeAccent,
      OrderStatus.ready => _teal,
      OrderStatus.claimRejected => const Color(0xFFF0181C),
      _ => _tealBorder,
    };
    final created = order.createdAt?.toLocal();
    return InkWell(
      key: ValueKey('dashboard-order-${order.id}'),
      onTap: () => context.go(AppRoutes.pharmacyOrderDetail
          .replaceFirst(':orderId', '${order.id}')),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time label
          SizedBox(
            width: 44,
            child: Text(
              created == null ? '' : clockTime(created),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _textLight,
                fontFamily: 'Sora',
              ),
            ),
          ),
          // Dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          // Connector line
          Container(
            width: 30,
            height: 1,
            color: accent.withValues(alpha: 0.4),
          ),
          // Card
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x80309CA3).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(width: 4, color: accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      order.patientName ?? 'Patient',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                        fontFamily: 'Sora',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        order.reference,
                                        if (order.prescriptionNumber != null)
                                          order.prescriptionNumber!,
                                      ].join(' · '),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _textLight,
                                        fontFamily: 'Sora',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    _statusLine(order.status.label, accent),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    created == null ? '' : shortDate(created),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: _textMuted,
                                      fontFamily: 'Sora',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _pill('Open'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Incoming Prescriptions Section ──────────────────────────────────────
  Widget _buildIncomingPrescriptionsSection(
      BuildContext context, _DashboardViewModel vm) {
    final scripts = vm.awaiting.take(_previewRows).toList();
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: 'assets/incoming-prescriptions-icon.png',
            title: 'Incoming Prescriptions',
            trailing: _seeAll(context, AppRoutes.pharmacyDispensingQueue,
                key: 'dashboard-all-scripts'),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          if (!vm.scriptsLoaded)
            _placeholder('Loading prescriptions…')
          else if (scripts.isEmpty)
            _placeholder('No claimed prescriptions waiting.')
          else ...[
            _buildTableHeader(),
            const SizedBox(height: 6),
            for (final script in scripts) _buildPrescriptionRow(context, script),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Row(
      children: [
        Expanded(flex: 2, child: _HeaderText('Patient')),
        Expanded(flex: 2, child: _HeaderText('Reference')),
        Expanded(flex: 2, child: _HeaderText('Medication')),
        Expanded(flex: 1, child: _HeaderText('Claimed')),
        Expanded(flex: 1, child: _HeaderText('Status')),
        Expanded(flex: 1, child: _HeaderText('Action')),
      ],
    );
  }

  Widget _buildPrescriptionRow(
      BuildContext context, ClaimedPrescription script) {
    const cell = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: _textMuted,
      fontFamily: 'Sora',
    );
    final claimed = script.claimedAt?.toLocal();
    return Padding(
      key: ValueKey('dashboard-script-${script.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgLight,
                    border: Border.all(color: _teal, width: 1),
                  ),
                  child: const Icon(Icons.person, size: 14, color: _teal),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(script.patientName,
                      overflow: TextOverflow.ellipsis, style: cell),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(script.number,
                overflow: TextOverflow.ellipsis, style: cell),
          ),
          Expanded(
            flex: 2,
            child: Text(script.medicineSummary,
                overflow: TextOverflow.ellipsis, style: cell),
          ),
          Expanded(
            flex: 1,
            child: Text(claimed == null ? '' : shortDate(claimed),
                style: cell),
          ),
          Expanded(flex: 1, child: _statusLine('New', _statusDotOrange)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => context.go(AppRoutes.pharmacyPrescriptionDetail
                    .replaceFirst(':prescriptionId', '${script.id}')),
                borderRadius: BorderRadius.circular(25),
                child: _pill('Dispense'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared pieces ───────────────────────────────────────────────────────

  Widget _card({required EdgeInsets padding, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 11, color: _sectionBorder),
              Expanded(child: Padding(padding: padding, child: child)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String icon,
    required String title,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 34,
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(icon, width: 21, height: 21),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'Sora',
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _seeAll(BuildContext context, String route, {required String key}) {
    return TextButton(
      key: ValueKey(key),
      onPressed: () => context.go(route),
      child: const Text(
        'See all',
        style: TextStyle(fontSize: 11, color: _teal, fontFamily: 'Sora'),
      ),
    );
  }

  Widget _placeholder(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11, color: _textMuted, fontFamily: 'Sora'),
        ),
      );

  Widget _statusLine(String label, Color colour) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colour,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: _textLight,
              fontFamily: 'Sora',
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _tealBorder,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'SF Pro',
        ),
      ),
    );
  }
}

// ─── View model ─────────────────────────────────────────────────────────────

class _DashboardViewModel {
  _DashboardViewModel({
    required this.userName,
    required this.orders,
    required this.awaiting,
    required this.dispensedCount,
    required this.ordersLoaded,
    required this.scriptsLoaded,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  factory _DashboardViewModel.fromStore(Store<AppState> store) {
    final orders = store.state.pharmacyOrdersState;
    final scripts = store.state.dispensingState;
    return _DashboardViewModel(
      userName: store.state.authState.userName,
      orders: orders.orders,
      awaiting: scripts.awaiting,
      dispensedCount: scripts.dispensed.length,
      ordersLoaded: orders.hasLoadedOnce,
      scriptsLoaded: scripts.hasLoadedOnce,
      loading: orders.isLoading || scripts.isLoading,
      error: orders.errorMessage ?? scripts.errorMessage,
      onRefresh: () {
        store.dispatch(const LoadPharmacyOrdersAction());
        store.dispatch(const LoadDispensingQueueAction());
      },
    );
  }

  final String? userName;
  final List<PharmacyOrder> orders;
  final List<ClaimedPrescription> awaiting;
  final int dispensedCount;
  final bool ordersLoaded;
  final bool scriptsLoaded;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  int get newOrders =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  int get readyForPickup =>
      orders.where((o) => o.status == OrderStatus.ready).length;

  /// Orders still moving, newest first.
  List<PharmacyOrder> get openOrders {
    final open = orders.where((o) => !o.status.isTerminal).toList();
    open.sort((a, b) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null || right == null) return 0;
      return right.compareTo(left);
    });
    return open;
  }

  @override
  bool operator ==(Object other) =>
      other is _DashboardViewModel &&
      other.userName == userName &&
      identical(other.orders, orders) &&
      identical(other.awaiting, awaiting) &&
      other.dispensedCount == dispensedCount &&
      other.ordersLoaded == ordersLoaded &&
      other.scriptsLoaded == scriptsLoaded &&
      other.loading == loading &&
      other.error == error;

  @override
  int get hashCode => Object.hash(userName, orders, awaiting, dispensedCount,
      ordersLoaded, scriptsLoaded, loading, error);
}

// ─── Formatting ─────────────────────────────────────────────────────────────

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}

/// "Monday, 16th November", as the Figma header reads.
String longDate(DateTime day) =>
    '${_weekdays[day.weekday - 1]}, ${_ordinal(day.day)} ${_months[day.month - 1]}';

/// "16 Nov".
String shortDate(DateTime day) =>
    '${day.day} ${_months[day.month - 1].substring(0, 3)}';

/// "08:20".
String clockTime(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0x66000000), // rgba(0,0,0,0.4)
        fontFamily: 'Sora',
      ),
    );
  }
}

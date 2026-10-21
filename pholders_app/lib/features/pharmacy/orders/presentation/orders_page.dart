import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_state.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/realtime/realtime_gateway.dart';
import '../../../../core/routing/app_routes.dart';
import '../data/order_workflow_api.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PharmacyOrderListPage(title: 'Orders');
}

class PharmacyOrderListPage extends StatefulWidget {
  final String title;
  final String? initialStatus;

  const PharmacyOrderListPage({
    super.key,
    this.title = 'Orders',
    this.initialStatus,
  });

  @override
  State<PharmacyOrderListPage> createState() => _PharmacyOrderListPageState();
}

class _PharmacyOrderListPageState extends State<PharmacyOrderListPage> {
  static const _textDark = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);
  static const _pendingOrange = Color(0xFFFBBF24);
  static const _processingBlue = Color(0xFF3B82F6);
  static const _limit = 20;

  final _api = OrderWorkflowApi(sl<Dio>());
  final _searchController = TextEditingController();
  final _realtime = sl<RealtimeGateway>();
  List<OrderJson> _orders = const [];
  List<String> _statuses = const [];
  String? _selectedStatus;
  String? _error;
  String? _connectedToken;
  int _offset = 0;
  int _total = 0;
  bool _loading = true;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = StoreProvider.of<AppState>(context).state.authState.token;
    if (token != null && token != _connectedToken) {
      _connectedToken = token;
      _realtime.connect(
        token,
        onOrderEvent: (_, __) => _loadOrders(),
        onReconnect: _loadOrders,
      );
      _loadStatusesAndOrders();
    }
  }

  Future<void> _loadStatusesAndOrders() async {
    try {
      final data = await _api.fetchStatuses();
      final statuses = (data['statuses'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      if (mounted) {
        setState(() => _statuses = statuses);
      }
    } catch (_) {
      // Queue loading remains available if status metadata is unavailable.
    }
    await _loadOrders();
  }

  Future<void> _loadOrders({bool reset = false}) async {
    if (reset) _offset = 0;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await _api.fetchPharmacyQueue(
        status: _selectedStatus,
        search: _searchController.text,
        limit: _limit,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _orders = page.orders;
        _offset = page.offset;
        _total = page.total;
      });
    } on DioException catch (error) {
      if (mounted) setState(() => _error = ApiException.fromDio(error).message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _realtime.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _loadOrders(reset: true),
                );
              },
              decoration: InputDecoration(
                hintText: 'Search order ID, prescription number, or patient',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _loadOrders(reset: true);
                  },
                  icon: const Icon(Icons.close),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_statuses.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip(null, 'All'),
                    for (final status in _statuses)
                      _statusChip(status, _label(status)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildTable()),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
              SizedBox(height: 4),
              Text('Manage customer orders and deliveries',
                  style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Orders are created by patients. Pharmacy-side order creation is not available.',
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF309CA3),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/plus-icon.png',
                    width: 18, height: 18, color: Colors.black),
                const SizedBox(width: 8),
                const Text('New Order',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String? status, String label) {
    final selected = status == _selectedStatus;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedStatus = status);
          _loadOrders(reset: true);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _textMuted)),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _loadOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) return const Center(child: Text('No orders found.'));
    return RefreshIndicator(
      onRefresh: () => _loadOrders(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          color: Colors.white,
          child: Row(
            children: [
              Container(width: 11, color: const Color(0xFF6DD0D8)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: _ColHeader('Order ID')),
                          Expanded(flex: 3, child: _ColHeader('Patient')),
                          Expanded(flex: 2, child: _ColHeader('Items')),
                          Expanded(flex: 2, child: _ColHeader('Total')),
                          Expanded(flex: 2, child: _ColHeader('Payment')),
                          Expanded(flex: 2, child: _ColHeader('Status')),
                          Expanded(flex: 2, child: _ColHeader('Action')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) =>
                            _buildRow(_orders[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(OrderJson order) {
    final id = _string(order, ['id', 'order_id', 'orderId']);
    final patient = _map(order['patient']);
    final patientName = _string(
      patient,
      ['name', 'full_name', 'fullName'],
      fallback: _string(order, ['patient_name', 'patientName']),
    );
    final items = _list(
        order['items'] ?? order['medicines'] ?? order['prescription_items']);
    final status = _string(order, ['status'], fallback: 'unknown');
    final total =
        _string(order, ['total_amount', 'total', 'amount'], fallback: '-');
    final payment = _label(_string(order, ['payment_type'], fallback: '-'));
    return InkWell(
      onTap: id.isEmpty
          ? null
          : () => context.go(AppRoutes.pharmacyOrderDetail
              .replaceFirst(':orderId', Uri.encodeComponent(id))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text('#$id',
                    style: const TextStyle(fontSize: 13, color: _textDark))),
            Expanded(
                flex: 3,
                child: Text(patientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _textDark))),
            Expanded(
                flex: 2,
                child: Text('${items.length} Items',
                    style: const TextStyle(fontSize: 13, color: _textMuted))),
            Expanded(
                flex: 2,
                child: Text(total,
                    style: const TextStyle(fontSize: 13, color: _textDark))),
            Expanded(
                flex: 2,
                child: Text(payment,
                    style: const TextStyle(fontSize: 12, color: _textMuted))),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: status == 'pending'
                              ? _pendingOrange
                              : _processingBlue)),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(_label(status),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _textMuted))),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: id.isEmpty
                      ? null
                      : () => context.go(AppRoutes.pharmacyOrderDetail
                          .replaceFirst(':orderId', Uri.encodeComponent(id))),
                  child: const Text('View'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final nextOffset = _offset + _limit;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Total: $_total'),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous page',
          onPressed: _offset == 0 || _loading
              ? null
              : () {
                  _offset = (_offset - _limit).clamp(0, _total).toInt();
                  _loadOrders();
                },
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${_total == 0 ? 0 : _offset + 1}-'
            '${(_offset + _orders.length).clamp(0, _total)}'),
        IconButton(
          tooltip: 'Next page',
          onPressed: nextOffset >= _total || _loading
              ? null
              : () {
                  _offset = nextOffset;
                  _loadOrders();
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      );
}

String _label(String value) => value
    .split('_')
    .map((part) =>
        part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _string(Map<String, dynamic> value, List<String> keys,
    {String fallback = ''}) {
  for (final key in keys) {
    final item = value[key];
    if (item != null && '$item'.isNotEmpty) return '$item';
  }
  return fallback;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

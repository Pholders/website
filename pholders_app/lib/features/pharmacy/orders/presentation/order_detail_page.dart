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

/// Pharmacy Order Detail page matching the Figma design.
///
/// Shows full order information including patient info, items table,
/// totals, linked prescription, and payment information.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _api = OrderWorkflowApi(sl<Dio>());
  final _realtime = sl<RealtimeGateway>();
  OrderJson _order = const {};
  List<OrderJson> _history = const [];
  List<String> _statuses = const [];
  List<String> _allowedTransitions = const [];
  OrderJson? _dispenseSuggestions;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  String? _connectedToken;
  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF309CA3);
  static const Color _tealBorder = Color(0xFF6DD0D8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFE8F8F8);
  static const Color _tableBg = Color(0xFFE8F8F8);
  static const Color _bgLight = Color(0x33309CA3);

  String _orderStatus = 'Processing';

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = StoreProvider.of<AppState>(context).state.authState.token;
    if (token != null && token != _connectedToken) {
      _connectedToken = token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _realtime.connect(
          token,
          onOrderEvent: (_, __) => _loadOrder(),
          onReconnect: _loadOrder,
        );
      });
    }
  }

  @override
  void dispose() {
    _realtime.disconnect();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchOrder(widget.orderId);
      OrderJson metadata = const {};
      try {
        metadata = await _api.fetchStatuses();
      } catch (_) {
        // Order details and history are still useful without action metadata.
      }
      if (!mounted) return;
      setState(() {
        _order = _asMap(data['order']);
        _history = _asMapList(data['history']);
        _statuses = (metadata['statuses'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false);
        final transitions = _asMap(metadata['allowedTransitions']);
        final allowed = transitions[_status];
        _allowedTransitions = allowed is List
            ? allowed.whereType<String>().toList(growable: false)
            : const [];
      });
    } on DioException catch (error) {
      if (mounted) setState(() => _error = ApiException.fromDio(error).message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _status => _value(_order, ['status'], fallback: 'unknown');

  Map<String, dynamic> get _patient => _asMap(_order['patient']);

  Map<String, dynamic> get _prescription => _asMap(_order['prescription']);

  List<OrderJson> get _orderItems => _asMapList(
        _order['items'] ??
            _order['medicines'] ??
            _order['prescription_items'] ??
            _prescription['items'],
      );

  String _patientValue(List<String> keys) =>
      _value(_patient, keys, fallback: 'Not provided');

  Widget _buildWorkflowActions() {
    final actions = <Widget>[];
    for (final status in _allowedTransitions) {
      if (status == 'rejected') continue;
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: FilledButton.tonal(
            onPressed: _acting ? null : () => _transition(status),
            child: Text(_label(status)),
          ),
        ),
      );
    }
    if (_allowedTransitions.contains('rejected')) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: OutlinedButton(
            onPressed: _acting ? null : () => _transition('rejected'),
            child: const Text('Reject'),
          ),
        ),
      );
    }
    if (_status == 'preparing') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: OutlinedButton.icon(
            onPressed: _acting ? null : _loadDispenseSuggestions,
            icon: const Icon(Icons.medication_outlined),
            label: const Text('Dispense items'),
          ),
        ),
      );
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Order Actions'),
        const SizedBox(height: 8),
        Wrap(children: actions),
        if (_acting) const LinearProgressIndicator(),
        if (_dispenseSuggestions != null) _buildDispenseSuggestions(),
      ],
    );
  }

  Widget _buildDispenseSuggestions() {
    final suggestions = _dispenseSuggestions!;
    final lines = _suggestionLines(suggestions);
    final noMatch = suggestions['noMatch'] ?? suggestions['no_match'];
    final already =
        suggestions['alreadyDispensed'] ?? suggestions['already_dispensed'];
    final alreadyDispensed = already == true ||
        already is List && already.isNotEmpty ||
        already is Map && already.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${_value(line, [
                      'medicine_name',
                      'name',
                      'medication'
                    ], fallback: 'Medicine')} · '
                '${_candidateItems(line).where((candidate) => _inventoryItemId(candidate).isNotEmpty).length} inventory matches',
                style: const TextStyle(fontSize: 13, color: _textMuted),
              ),
            ),
          if (noMatch is List && noMatch.isNotEmpty)
            Text('${noMatch.length} item(s) have no inventory match.',
                style: const TextStyle(color: Colors.redAccent)),
          if (alreadyDispensed)
            const Text('These items have already been dispensed.'),
          if (!alreadyDispensed && lines.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _acting ? null : _confirmDispense,
                icon: const Icon(Icons.check),
                label: const Text('Confirm dispense'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadDispenseSuggestions() async {
    setState(() => _acting = true);
    try {
      final data = await _api.fetchDispenseSuggestions(widget.orderId);
      if (mounted) setState(() => _dispenseSuggestions = data);
    } on DioException catch (error) {
      if (mounted) _showMessage(ApiException.fromDio(error).message);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmDispense() async {
    final suggestions = _dispenseSuggestions;
    if (suggestions == null) return;
    final lines = _suggestionLines(suggestions);
    final matchedLines = lines
        .where((line) => _candidateItems(line)
            .any((candidate) => _inventoryItemId(candidate).isNotEmpty))
        .toList(growable: false);
    if (matchedLines.isEmpty) {
      _showMessage('No matched items are available to dispense.');
      return;
    }
    final selections = <int, String>{};
    final quantities = <int, TextEditingController>{};
    for (var index = 0; index < matchedLines.length; index++) {
      final line = matchedLines[index];
      final candidates = _candidateItems(line)
          .where((candidate) => _inventoryItemId(candidate).isNotEmpty)
          .toList(growable: false);
      selections[index] = _inventoryItemId(candidates.first);
      quantities[index] = TextEditingController(
        text:
            '${line['quantity'] ?? line['prescribed_quantity'] ?? line['prescribedQuantity'] ?? ''}',
      );
    }
    final payload = await showDialog<List<OrderJson>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm dispensing'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < matchedLines.length; index++)
                    _buildDispenseLine(
                      matchedLines[index],
                      index,
                      selections,
                      quantities,
                      () => setDialogState(() {}),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final items = <OrderJson>[];
                for (var index = 0; index < matchedLines.length; index++) {
                  final line = matchedLines[index];
                  final prescriptionItemId = _value(
                    line,
                    ['prescription_item_id', 'prescriptionItemId', 'id'],
                    fallback: _value(_asMap(line['prescription_item']), ['id']),
                  );
                  final inventoryItemId = selections[index] ?? '';
                  final quantity = int.tryParse(quantities[index]!.text);
                  if (prescriptionItemId.isEmpty ||
                      inventoryItemId.isEmpty ||
                      quantity == null ||
                      quantity <= 0) {
                    continue;
                  }
                  items.add({
                    'prescription_item_id':
                        int.tryParse(prescriptionItemId) ?? prescriptionItemId,
                    'inventory_item_id':
                        int.tryParse(inventoryItemId) ?? inventoryItemId,
                    'quantity': quantity,
                  });
                }
                Navigator.pop(context, items);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    for (final controller in quantities.values) {
      controller.dispose();
    }
    if (payload == null || payload.isEmpty) return;
    await _runAction(() => _api.dispenseItems(widget.orderId, payload));
    await _loadDispenseSuggestions();
  }

  Widget _buildDispenseLine(
    OrderJson line,
    int index,
    Map<int, String> selections,
    Map<int, TextEditingController> quantities,
    VoidCallback onChanged,
  ) {
    final candidates = _candidateItems(line)
        .where((candidate) => _inventoryItemId(candidate).isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_value(line, ['medicine_name', 'name', 'medication'],
            fallback: 'Medicine')),
        DropdownButtonFormField<String>(
          initialValue: selections[index],
          decoration: const InputDecoration(labelText: 'Inventory item'),
          items: [
            for (final candidate in candidates)
              DropdownMenuItem(
                value: _inventoryItemId(candidate),
                child: Text(_value(
                  _asMap(candidate['inventory_item']).isNotEmpty
                      ? _asMap(candidate['inventory_item'])
                      : candidate,
                  ['name', 'item_name', 'medicine_name'],
                  fallback: 'Inventory item',
                )),
              ),
          ],
          onChanged: (value) {
            selections[index] = value ?? '';
            onChanged();
          },
        ),
        TextField(
          controller: quantities[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildStatusHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Status History'),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          const Text('No status history available.',
              style: TextStyle(fontSize: 13, color: _textMuted))
        else
          for (final entry in _history)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 10, color: _teal),
              title:
                  Text(_label(_value(entry, ['status'], fallback: 'Updated'))),
              subtitle: Text([
                _value(entry, ['created_at', 'createdAt', 'timestamp']),
                _value(entry, ['notes', 'reason', 'actor_name']),
              ].where((value) => value.isNotEmpty).join(' · ')),
            ),
      ],
    );
  }

  Future<void> _transition(String nextStatus) async {
    String? response;
    if (nextStatus == 'accepted') {
      response = await _showAcceptDialog();
      if (response == null) return;
      final fields = response.split('\u0000');
      final amount = num.tryParse(fields.first.trim());
      if (amount == null) {
        _showMessage('Enter a valid quote amount.');
        return;
      }
      await _runAction(() => _api.acceptOrder(
            widget.orderId,
            totalAmount: amount,
            notes: fields.length > 1 ? fields[1] : null,
          ));
      return;
    }
    if (nextStatus == 'rejected') {
      response = await _showTextDialog('Reject order', 'Reason');
      if (response == null || response.trim().isEmpty) return;
      await _runAction(
          () => _api.rejectOrder(widget.orderId, response!.trim()));
      return;
    }
    if (nextStatus == 'cancelled') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel order?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep order'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel order'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _runAction(() => _api.updateStatus(widget.orderId, nextStatus));
  }

  Future<void> _runAction(Future<OrderJson> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      await _loadOrder();
      if (mounted) _showMessage('Order updated.');
    } on DioException catch (error) {
      if (mounted) _showMessage(ApiException.fromDio(error).message);
    } catch (error) {
      if (mounted) _showMessage('$error');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<String?> _showAcceptDialog() async {
    final amountController = TextEditingController(
      text: _value(_order, ['total_amount', 'total', 'amount']),
    );
    final notesController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total quote'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              '${amountController.text}\u0000${notesController.text}',
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    amountController.dispose();
    notesController.dispose();
    return result;
  }

  Future<String?> _showTextDialog(String title, String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8F8F8),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 12),
            _buildDetailCard(context),
          ],
        ),
      ),
    );
  }

  // ─── Page Header ─────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
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
                'Manage customer orders and deliveries',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => _showMessage(
            'Orders are created by patients. Pharmacy-side order creation is not available.',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/plus-icon.png',
                    width: 18, height: 18, color: Colors.black),
                const SizedBox(width: 8),
                const Text(
                  'New Order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in _statuses)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: status == _status ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label(status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: status == _status ? Colors.white : _textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Detail Card ─────────────────────────────────────────────────────────
  Widget _buildDetailCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 11, color: _tealBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailHeader(context),
                      const SizedBox(height: 20),
                      _buildOrderMeta(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Patient Information'),
                      const SizedBox(height: 12),
                      _buildField('Patient',
                          _patientValue(['name', 'full_name', 'fullName'])),
                      _buildField(
                          'Phone',
                          _patientValue(
                              ['phone', 'phone_number', 'phoneNumber'])),
                      _buildField('Email', _patientValue(['email'])),
                      const SizedBox(height: 24),
                      _buildWorkflowActions(),
                      const SizedBox(height: 24),
                      _buildItemsSection(),
                      const SizedBox(height: 24),
                      _buildDeliveryTracking(),
                      const SizedBox(height: 24),
                      _buildTotalSection(),
                      const SizedBox(height: 24),
                      _buildLinkedPrescription(),
                      const SizedBox(height: 24),
                      _buildPaymentInformation(),
                      const SizedBox(height: 24),
                      _buildStatusHistory(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Detail Header ───────────────────────────────────────────────────────
  Widget _buildDetailHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.pharmacyOrders),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _bgLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 16, color: _teal),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Orders',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '> #${widget.orderId}',
          style: TextStyle(fontSize: 14, color: _textMuted),
        ),
        const Spacer(),
        const _IconBtn(assetPath: 'assets/share-icon.png'),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/printer-icon.png'),
        const SizedBox(width: 8),
        const _IconBtn(assetPath: 'assets/call-icon.png'),
      ],
    );
  }

  // ─── Order Meta ──────────────────────────────────────────────────────────
  Widget _buildOrderMeta() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order No.',
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                '#${widget.orderId}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on: ${_value(_order, [
                      'created_at',
                      'createdAt',
                      'created_on'
                    ], fallback: 'Not provided')}',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 10),
              // Current status
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003BFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF9D358),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_label(_status),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          _label(_value(_order, ['fulfillment_type', 'fulfillmentType'],
              fallback: 'Fulfillment not provided')),
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ],
    );
  }

  // ─── Section Title ───────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );
  }

  // ─── Field Row ───────────────────────────────────────────────────────────
  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, color: _textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Items Section ───────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Items'),
            const SizedBox(width: 4),
            Text('(${_orderItems.length})',
                style: TextStyle(fontSize: 14, color: _textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Header
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(width: 24),
                    const Expanded(
                      flex: 3,
                      child: const Text('Order ID',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    const Expanded(
                      flex: 2,
                      child: const Text('Dosage',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    const Expanded(
                      flex: 1,
                      child: const Text('Qty',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                    const Expanded(
                      flex: 2,
                      child: const Text('Price',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD1F5F5)),
              for (var index = 0; index < _orderItems.length; index++)
                _buildItemRow(
                  '${index + 1}.',
                  _value(_orderItems[index],
                      ['medicine_name', 'name', 'medication'],
                      fallback: 'Medicine'),
                  _value(_orderItems[index], ['dosage', 'strength'],
                      fallback: '-'),
                  '${_orderItems[index]['quantity'] ?? '-'}',
                  '${_orderItems[index]['price'] ?? _orderItems[index]['unit_price'] ?? '-'}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Delivery Tracking ─────────────────────────────────────────────────
  Widget _buildDeliveryTracking() {
    final progress = _orderStatus == 'Out for Delivery'
        ? 0.8
        : _orderStatus == 'Ready'
            ? 0.5
            : _orderStatus == 'Completed'
                ? 1.0
                : 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Delivery Tracking'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Method: In-Store Pickup', style: const TextStyle(fontSize: 13, color: _textMuted)),
              const SizedBox(height: 6),
              const Text('ETA: 25 Mar 2026 • 11:00 AM', style: const TextStyle(fontSize: 13, color: _textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                      backgroundColor: _tableBg,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_orderStatus, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(
      String num, String name, String dosage, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(num, style: TextStyle(fontSize: 12, color: _textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(name,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
          Expanded(
            flex: 2,
            child:
                Text(dosage, style: TextStyle(fontSize: 13, color: _textMuted)),
          ),
          Expanded(
            flex: 1,
            child: Text(qty,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(price,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
        ],
      ),
    );
  }

  // ─── Total Section ───────────────────────────────────────────────────────
  Widget _buildTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Total'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildTotalRow(
                  'Subtotal', _value(_order, ['subtotal'], fallback: '-')),
              _buildTotalRow(
                  'Delivery',
                  _value(_order, ['delivery_fee', 'deliveryFee'],
                      fallback: '-')),
              const Divider(height: 16, color: Color(0xFFD1F5F5)),
              _buildTotalRow(
                  'Total',
                  _value(_order, ['total_amount', 'total', 'amount'],
                      fallback: '-'),
                  bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: _textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Linked Prescription ─────────────────────────────────────────────────
  Widget _buildLinkedPrescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Linked Prescription'),
        const SizedBox(height: 12),
        _buildField(
            'Prescription',
            _value(_prescription, ['prescription_number', 'number', 'id'],
                fallback: 'Not provided')),
        _buildField(
            'Issued by',
            _value(_asMap(_prescription['doctor']), ['name', 'full_name'],
                fallback: _value(_prescription, ['doctor_name', 'prescriber'],
                    fallback: 'Not provided'))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'View Prescription',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Payment Information ─────────────────────────────────────────────────
  Widget _buildPaymentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Information'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _tableBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildTotalRow(
                  'Payment Method',
                  _label(_value(_order, ['payment_type'],
                      fallback: 'Not provided'))),
              _buildTotalRow(
                  'Status',
                  _label(_value(_order, ['payment_status'],
                      fallback: 'Not provided'))),
              _buildTotalRow(
                  'Transaction ID',
                  _value(_order, ['transaction_id', 'transactionId'],
                      fallback: 'Not provided')),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Order Status Progression ──────────────────────────────────────────────

  String get _orderActionLabel {
    switch (_orderStatus) {
      case 'Processing': return 'Mark Ready';
      case 'Ready': return 'Out for Delivery';
      case 'Out for Delivery': return 'Complete';
      default: return 'View';
    }
  }

  void _handleOrderAction() {
    String? next;
    switch (_orderStatus) {
      case 'Processing': next = 'Ready'; break;
      case 'Ready': next = 'Out for Delivery'; break;
      case 'Out for Delivery': next = 'Completed'; break;
    }
    if (next == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Move order to "$next"?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          next == 'Ready'
              ? 'This will mark the order as ready for collection. The patient will be notified.'
              : next == 'Out for Delivery'
                  ? 'Confirm the order is out for delivery.'
                  : 'Confirm the order has been completed and collected/delivered.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _orderStatus = next!);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✓ Order #10234 — $next'),
                backgroundColor: _teal,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.assetPath});
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0x33309CA3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Image.asset(assetPath, width: 16, height: 16),
      ),
    );
  }
}

String _label(String value) => value
    .split('_')
    .map((part) =>
        part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _value(Map<String, dynamic> data, List<String> keys,
    {String fallback = ''}) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<OrderJson> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => _asMap(item)).toList(growable: false);
}

List<OrderJson> _suggestionLines(OrderJson data) => _asMapList(
      data['lines'] ??
          data['medicineLines'] ??
          data['medicine_lines'] ??
          data['items'],
    );

List<OrderJson> _candidateItems(OrderJson line) => _asMapList(
      line['candidateInventoryItems'] ??
          line['candidate_inventory_items'] ??
          line['candidateItems'] ??
          line['candidate_items'] ??
          line['candidates'],
    );

String _inventoryItemId(OrderJson candidate) => _value(
      candidate,
      ['inventory_item_id', 'inventoryItemId', 'id'],
      fallback: _value(_asMap(candidate['inventory_item']), ['id']),
    );

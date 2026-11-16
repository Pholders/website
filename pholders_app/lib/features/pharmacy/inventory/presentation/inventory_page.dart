import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/di/service_locator.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_item.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.repository});

  final InventoryRepository? repository;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const _pageSize = 50;
  static const _teal = Color(0xFF309CA3);
  static const _textDark = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);

  late final InventoryRepository _repository;
  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<InventoryItem> _items = const [];
  InventorySummary? _summary;
  int _total = 0;
  int _requestId = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMutating = false;
  bool _lowStockOnly = false;
  bool _expiringSoonOnly = false;
  bool _includeInactive = false;
  String? _errorMessage;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? sl<InventoryRepository>();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (append && (_isLoading || _isLoadingMore)) return;
    final requestId = ++_requestId;
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
        _summary = null;
        _summaryError = null;
      }
    });

    try {
      final page = await _repository.fetchItems(
        search: _searchController.text,
        lowStock: _lowStockOnly,
        expiringWithinDays: _expiringSoonOnly ? 30 : null,
        includeInactive: _includeInactive,
        limit: _pageSize,
        offset: append ? _items.length : 0,
      );
      InventorySummary? summary = _summary;
      String? summaryError;
      if (!append) {
        try {
          summary = await _repository.fetchSummary();
        } on ApiException catch (error) {
          summaryError = error.message;
        }
      }
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = append ? [..._items, ...page.items] : page.items;
        _total = page.total;
        _summary = summary;
        _summaryError = summaryError;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() => _errorMessage = error.message);
      }
    } catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() => _errorMessage = 'Inventory could not be loaded: $error');
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    setState(() {});
    _searchTimer = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _showEditor([InventoryItem? item]) async {
    final formKey = GlobalKey<FormState>();
    final fields = <String, TextEditingController>{
      'sku': TextEditingController(text: item?.sku ?? ''),
      'medication_name':
          TextEditingController(text: item?.medicationName ?? ''),
      'generic_name': TextEditingController(text: item?.genericName ?? ''),
      'dosage': TextEditingController(text: item?.dosage ?? ''),
      'pack_size': TextEditingController(text: item?.packSize ?? ''),
      'unit': TextEditingController(text: item?.unit ?? ''),
      'quantity_on_hand': TextEditingController(
        text: item == null ? '0' : '${item.quantityOnHand}',
      ),
      'low_stock_threshold': TextEditingController(
        text: item == null ? '0' : '${item.lowStockThreshold}',
      ),
      'unit_price': TextEditingController(
        text: item?.unitPrice?.toStringAsFixed(2) ?? '',
      ),
      'expiry_date': TextEditingController(
        text: item?.expiryDate?.toIso8601String().split('T').first ?? '',
      ),
      'supplier': TextEditingController(text: item?.supplier ?? ''),
      'notes': TextEditingController(text: item?.notes ?? ''),
    };

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add stock item' : 'Edit stock item'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editorField(fields['medication_name']!, 'Medication name',
                      required: true),
                  _editorField(fields['sku']!, 'SKU'),
                  _editorField(fields['generic_name']!, 'Generic name'),
                  _editorField(fields['dosage']!, 'Dosage'),
                  _editorField(fields['pack_size']!, 'Pack size'),
                  _editorField(fields['unit']!, 'Unit'),
                  if (item == null)
                    _editorField(
                      fields['quantity_on_hand']!,
                      'Starting quantity',
                      numeric: true,
                      integer: true,
                    ),
                  _editorField(
                    fields['low_stock_threshold']!,
                    'Low-stock threshold',
                    numeric: true,
                    integer: true,
                  ),
                  _editorField(fields['unit_price']!, 'Unit price',
                      numeric: true),
                  _editorField(
                    fields['expiry_date']!,
                    'Expiry date (YYYY-MM-DD)',
                    date: true,
                  ),
                  _editorField(fields['supplier']!, 'Supplier'),
                  _editorField(fields['notes']!, 'Notes', maxLines: 3),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              final result = <String, dynamic>{};
              for (final key in [
                'sku',
                'medication_name',
                'generic_name',
                'dosage',
                'pack_size',
                'unit',
                'low_stock_threshold',
                'unit_price',
                'expiry_date',
                'supplier',
                'notes',
              ]) {
                final value = fields[key]!.text.trim();
                if (key == 'medication_name' || value.isNotEmpty) {
                  result[key] = value;
                }
              }
              if (item == null) {
                result['quantity_on_hand'] =
                    int.tryParse(fields['quantity_on_hand']!.text.trim()) ?? 0;
              } else {
                result.remove('low_stock_threshold');
                final threshold = fields['low_stock_threshold']!.text.trim();
                if (threshold.isNotEmpty) {
                  result['low_stock_threshold'] = int.parse(threshold);
                }
              }
              Navigator.pop(context, result);
            },
            child: Text(item == null ? 'Create item' : 'Save changes'),
          ),
        ],
      ),
    );

    for (final controller in fields.values) {
      controller.dispose();
    }
    if (payload == null) return;
    await _runMutation(() async {
      if (item == null) {
        await _repository.createItem(payload);
      } else {
        await _repository.updateItem(item.id, payload);
      }
    },
        successMessage:
            item == null ? 'Stock item added.' : 'Stock item updated.');
  }

  Widget _editorField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    bool integer = false,
    bool date = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label, isDense: true),
        validator: (value) {
          final text = value?.trim() ?? '';
          final parsedInteger = int.tryParse(text);
          if (required && text.isEmpty) return 'Required';
          if (integer && text.isNotEmpty && parsedInteger == null) {
            return 'Enter a whole number';
          }
          if (integer && parsedInteger != null && parsedInteger < 0) {
            return 'Cannot be negative';
          }
          if (numeric && text.isNotEmpty && double.tryParse(text) == null) {
            return 'Enter a valid number';
          }
          if (date && text.isNotEmpty && DateTime.tryParse(text) == null) {
            return 'Use YYYY-MM-DD';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _adjustQuantity(InventoryItem item) async {
    final formKey = GlobalKey<FormState>();
    final deltaController = TextEditingController();
    final notesController = TextEditingController();
    const reasons = [
      'initial_stock',
      'restock',
      'manual_adjust',
      'expired',
      'damaged',
      'return',
      'correction',
    ];
    var reason = 'restock';
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust ${item.medicationName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Current quantity: ${item.quantityOnHand} ${item.unit ?? ''}'),
                TextFormField(
                  controller: deltaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Change (+/- whole number)',
                  ),
                  validator: (value) {
                    final delta = int.tryParse(value?.trim() ?? '');
                    if (delta == null || delta == 0) {
                      return 'Enter a non-zero whole number';
                    }
                    if (item.quantityOnHand + delta < 0) {
                      return 'Stock cannot be reduced below zero';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: [
                    for (final value in reasons)
                      DropdownMenuItem(
                          value: value,
                          child: Text(value.replaceAll('_', ' '))),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => reason = value ?? reason),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, {
                  'delta': int.parse(deltaController.text.trim()),
                  'reason': reason,
                  'notes': notesController.text.trim(),
                });
              },
              child: const Text('Apply adjustment'),
            ),
          ],
        ),
      ),
    );
    deltaController.dispose();
    notesController.dispose();
    if (payload == null) return;
    await _runMutation(
      () => _repository.adjustQuantity(
        item.id,
        delta: payload['delta'] as int,
        reason: payload['reason'] as String,
        notes: payload['notes'] as String,
      ),
      successMessage: 'Stock quantity adjusted.',
    );
  }

  Future<void> _showHistory(InventoryItem item) async {
    try {
      final adjustments = await _repository.fetchAdjustments(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${item.medicationName} adjustments'),
          content: SizedBox(
            width: 520,
            child: adjustments.isEmpty
                ? const Center(child: Text('No stock adjustments recorded.'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: adjustments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = adjustments[index];
                      final delta =
                          entry['delta'] ?? entry['quantity_delta'] ?? '';
                      final reason = entry['reason'] ?? 'Adjustment';
                      final notes = entry['notes']?.toString();
                      final date = entry['created_at'] ?? entry['createdAt'];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('$reason · $delta'),
                        subtitle: Text([
                          if (date != null) date.toString(),
                          if (notes != null && notes.isNotEmpty) notes,
                        ].join('\n')),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deactivate(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate stock item?'),
        content: Text('${item.medicationName} will no longer be active.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runMutation(
      () => _repository.deactivateItem(item.id),
      successMessage: 'Stock item deactivated.',
    );
  }

  Future<void> _runMutation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isMutating = true);
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Inventory update failed: $error');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            _buildSummary(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 12),
            if (_isMutating) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventory',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
              SizedBox(height: 4),
              Text('Manage medication stock and availability',
                  style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _isMutating ? null : () => _showEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Add stock'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final summary = _summary;
    if (summary == null && _summaryError != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('Summary unavailable: $_summaryError',
            style: const TextStyle(color: _textMuted)),
      );
    }
    if (summary == null) return const LinearProgressIndicator(minHeight: 2);
    final values = [
      ('Active items', summary.totalActive, Icons.medication_outlined),
      ('Low stock', summary.lowStock, Icons.warning_amber_outlined),
      ('Out of stock', summary.outOfStock, Icons.remove_shopping_cart_outlined),
      ('Expiring soon', summary.expiringSoon, Icons.event_outlined),
      ('Expired', summary.expired, Icons.error_outline),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (label, value, icon) in values)
          SizedBox(
            width: 150,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: _teal),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('$value',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 11, color: _textMuted),
                              overflow: TextOverflow.ellipsis)
                        ])),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search name, SKU or supplier',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _load();
                      },
                      icon: const Icon(Icons.close),
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        FilterChip(
          label: const Text('Low stock'),
          selected: _lowStockOnly,
          onSelected: (value) => setState(() {
            _lowStockOnly = value;
            _load();
          }),
        ),
        FilterChip(
          label: const Text('Expiry: 30 days (includes expired)'),
          selected: _expiringSoonOnly,
          onSelected: (value) => setState(() {
            _expiringSoonOnly = value;
            _load();
          }),
        ),
        FilterChip(
          label: const Text('Include inactive'),
          selected: _includeInactive,
          onSelected: (value) => setState(() {
            _includeInactive = value;
            _load();
          }),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: _textMuted),
            const SizedBox(height: 10),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 36, color: _textMuted),
            const SizedBox(height: 10),
            const Text('No stock items found.'),
            if (_errorMessage != null) Text(_errorMessage!),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (_errorMessage != null)
          Align(
              alignment: Alignment.centerLeft,
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red))),
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Medication')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Stock'), numeric: true),
                    DataColumn(label: Text('Threshold'), numeric: true),
                    DataColumn(label: Text('Unit price'), numeric: true),
                    DataColumn(label: Text('Expiry')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [for (final item in _items) _buildRow(item)],
                ),
              ),
            ),
          ),
        ),
        if (_items.length < _total)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: _isLoadingMore ? null : () => _load(append: true),
              child: Text(_isLoadingMore
                  ? 'Loading...'
                  : 'Load more (${_total - _items.length} remaining)'),
            ),
          ),
      ],
    );
  }

  DataRow _buildRow(InventoryItem item) {
    final statusColor = switch (item.stockStatus) {
      'In stock' => const Color(0xFF15803D),
      'Low stock' => const Color(0xFFB45309),
      'Out of stock' || 'Expired' => const Color(0xFFB91C1C),
      _ => _textMuted,
    };
    return DataRow(
      cells: [
        DataCell(SizedBox(
            width: 190,
            child: Text(item.medicationName, overflow: TextOverflow.ellipsis))),
        DataCell(Text(item.sku ?? '—')),
        DataCell(Text('${item.quantityOnHand} ${item.unit ?? ''}'.trim())),
        DataCell(Text('${item.lowStockThreshold}')),
        DataCell(Text(item.unitPrice == null
            ? '—'
            : 'R ${item.unitPrice!.toStringAsFixed(2)}')),
        DataCell(
            Text(item.expiryDate?.toIso8601String().split('T').first ?? '—')),
        DataCell(Text(item.stockStatus,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600))),
        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Stock item actions',
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _showEditor(item);
                case 'adjust':
                  _adjustQuantity(item);
                case 'history':
                  _showHistory(item);
                case 'deactivate':
                  _deactivate(item);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit details')),
              const PopupMenuItem(
                  value: 'adjust', child: Text('Adjust quantity')),
              const PopupMenuItem(
                  value: 'history', child: Text('Adjustment history')),
              if (item.isActive)
                const PopupMenuItem(
                    value: 'deactivate', child: Text('Deactivate')),
            ],
          ),
        ),
      ],
    );
  }
}

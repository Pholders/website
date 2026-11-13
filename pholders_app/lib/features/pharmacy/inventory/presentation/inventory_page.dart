import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../data/inventory_item.dart';
import '../data/inventory_repository.dart';

/// Stock management: what the pharmacy has on its shelves.
///
/// Everything here is saved on the server, so a refresh or another device
/// shows the same stock. Quantity only ever changes through an adjustment
/// with a reason, which the backend logs.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key, this.repository, this.today});

  /// Injected by tests; the app uses the registered one.
  final InventoryRepository? repository;

  /// Fixed by tests so expiry labels do not depend on the clock.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    return _InventoryBody(
      repository: repository ?? sl<InventoryRepository>(),
      today: today,
    );
  }
}

// ─── Colours ─────────────────────────────────────────────────────────────────
const Color _teal = Color(0xFF309CA3);
const Color _aqua = Color(0xFF6DD0D8);
const Color _textDark = Color(0xFF1F2937);
const Color _textMuted = Color(0xFF6B7280);
const Color _rule = Color(0xFFF3F4F6);
const Color _okGreen = Color(0xFF16A34A);
const Color _lowOrange = Color(0xFFF59E0B);
const Color _outRed = Color(0xFFDC2626);

/// Below this width the table scrolls sideways instead of squashing.
const double _tableMinWidth = 980;

class _InventoryBody extends StatefulWidget {
  const _InventoryBody({required this.repository, this.today});

  final InventoryRepository repository;
  final DateTime? today;

  @override
  State<_InventoryBody> createState() => _InventoryBodyState();
}

class _InventoryBodyState extends State<_InventoryBody> {
  static const _tabs = <(InventoryFilter, String)>[
    (InventoryFilter.all, 'All'),
    (InventoryFilter.lowStock, 'Low stock'),
    (InventoryFilter.expiringSoon, 'Expiring soon'),
  ];

  InventoryFilter _filter = InventoryFilter.all;
  final _search = TextEditingController();
  Timer? _searchDebounce;

  List<InventoryItem> _items = const [];
  InventorySummary? _summary;
  bool _loading = true;
  String? _error;

  /// Ignores answers to a request that a newer one has replaced.
  int _generation = 0;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.fetchItems(filter: _filter, search: _search.text),
        widget.repository.fetchSummary(),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = results[0] as List<InventoryItem>;
        _summary = results[1] as InventorySummary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error, 'Your stock could not be loaded.');
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _selectFilter(InventoryFilter filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _addItem() async {
    final saved = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => _ItemFormDialog(
        onSave: (fields) => widget.repository.create(fields),
      ),
    );
    if (saved == null) return;
    _toast('${saved.medicationName} added to your stock');
    await _load();
  }

  Future<void> _editItem(InventoryItem item) async {
    final saved = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => _ItemFormDialog(
        existing: item,
        onSave: (fields) => widget.repository.update(item.id, fields),
      ),
    );
    if (saved == null) return;
    _toast('${saved.medicationName} saved');
    await _load();
  }

  Future<void> _adjustStock(InventoryItem item) async {
    final saved = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => _AdjustDialog(
        item: item,
        onSave: (delta, reason, notes) => widget.repository
            .adjust(item.id, delta: delta, reason: reason, notes: notes),
      ),
    );
    if (saved == null) return;
    _toast('${saved.medicationName}: ${saved.quantityOnHand} on hand');
    await _load();
  }

  Future<void> _removeItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${item.medicationName}?'),
        content: const Text(
          'It leaves your stock list. Its stock history is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _outRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.remove(item.id);
      if (!mounted) return;
      _toast('${item.medicationName} removed');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _toast(_messageFor(error, 'It could not be removed.'));
    }
  }

  // ─── Layout ────────────────────────────────────────────────────────────────

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
            const SizedBox(height: 4),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage medication stock and availability',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ),
        Material(
          color: _teal,
          shape: const StadiumBorder(),
          child: InkWell(
            key: const ValueKey('inventory-add'),
            customBorder: const StadiumBorder(),
            onTap: _addItem,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Item',
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
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final summary = _summary;
    String count(int Function(InventorySummary) pick) =>
        summary == null ? '–' : '${pick(summary)}';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(
          label: 'Items in stock list',
          value: count((s) => s.totalActive),
          colour: _teal,
        ),
        _StatTile(
          label: 'Low stock',
          value: count((s) => s.lowStock),
          colour: _lowOrange,
        ),
        _StatTile(
          label: 'Out of stock',
          value: count((s) => s.outOfStock),
          colour: _outRed,
        ),
        _StatTile(
          label: 'Expiring in $expiringSoonDays days',
          value: count((s) => s.expiringSoon),
          colour: _lowOrange,
        ),
        _StatTile(
          label: 'Expired',
          value: count((s) => s.expired),
          colour: _outRed,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final (filter, label) in _tabs)
                InkWell(
                  key: ValueKey('inventory-tab-${filter.name}'),
                  onTap: () => _selectFilter(filter),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _filter == filter ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _filter == filter ? Colors.white : _textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 240,
          height: 38,
          child: TextField(
            key: const ValueKey('inventory-search'),
            controller: _search,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search name, generic or SKU',
              hintStyle: const TextStyle(fontSize: 13, color: _textMuted),
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
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
            Container(width: 11, color: _aqua),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width =
                      math.max(constraints.maxWidth, _tableMinWidth);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          const _HeaderRow(),
                          Expanded(child: _buildRows()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    final error = _error;
    if (error != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: error,
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }
    if (_items.isEmpty) {
      final searching = _search.text.trim().isNotEmpty;
      final text = searching
          ? 'Nothing in your stock matches "${_search.text.trim()}".'
          : switch (_filter) {
              InventoryFilter.all =>
                'No stock yet. Add the medicines you keep with Add Item.',
              InventoryFilter.lowStock => 'Nothing is low on stock.',
              InventoryFilter.expiringSoon =>
                'Nothing expires in the next $expiringSoonDays days.',
            };
      return _Message(icon: Icons.inventory_2_outlined, text: text);
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ItemRow(
          item: item,
          today: _today,
          onAdjust: () => _adjustStock(item),
          onEdit: () => _editItem(item),
          onRemove: () => _removeItem(item),
        );
      },
    );
  }
}

// ─── Table pieces ────────────────────────────────────────────────────────────

const _flex = (medication: 4, sku: 2, onHand: 3, lowAt: 2, price: 2, expiry: 2, action: 3);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: _flex.medication, child: const _ColHeader('Medication')),
          Expanded(flex: _flex.sku, child: const _ColHeader('SKU')),
          Expanded(flex: _flex.onHand, child: const _ColHeader('On hand')),
          Expanded(flex: _flex.lowAt, child: const _ColHeader('Low at')),
          Expanded(flex: _flex.price, child: const _ColHeader('Unit price')),
          Expanded(flex: _flex.expiry, child: const _ColHeader('Expiry')),
          Expanded(flex: _flex.action, child: const _ColHeader('Action')),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.today,
    required this.onAdjust,
    required this.onEdit,
    required this.onRemove,
  });

  final InventoryItem item;
  final DateTime today;
  final VoidCallback onAdjust;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final detail = [item.dosage, item.genericName]
        .whereType<String>()
        .join(' · ');
    final (stockLabel, stockColour) = item.isOutOfStock
        ? ('Out of stock', _outRed)
        : item.isLowStock
            ? ('Low stock', _lowOrange)
            : ('In stock', _okGreen);

    final expiry = item.expiryDate;
    final expiryColour = item.isExpired(today)
        ? _outRed
        : item.expiresWithin(expiringSoonDays, today)
            ? _lowOrange
            : _textDark;

    return Container(
      key: ValueKey('inventory-row-${item.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _rule)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _flex.medication,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicationName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: _flex.sku,
            child: Text(
              item.sku ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          Expanded(
            flex: _flex.onHand,
            child: Row(
              children: [
                Text(
                  '${item.quantityOnHand}${item.unit == null ? '' : ' ${item.unit}'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: stockColour),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    stockLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: stockColour),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _flex.lowAt,
            child: Text(
              '${item.lowStockThreshold}',
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          Expanded(
            flex: _flex.price,
            child: Text(
              item.unitPrice == null ? '—' : formatRand(item.unitPrice!),
              style: const TextStyle(fontSize: 13, color: _textDark),
            ),
          ),
          Expanded(
            flex: _flex.expiry,
            child: Text(
              expiry == null ? '—' : formatDay(expiry),
              style: TextStyle(fontSize: 13, color: expiryColour),
            ),
          ),
          Expanded(
            flex: _flex.action,
            child: Row(
              children: [
                Material(
                  color: _aqua,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: ValueKey('inventory-adjust-${item.id}'),
                    customBorder: const StadiumBorder(),
                    onTap: onAdjust,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(
                        'Adjust stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  key: ValueKey('inventory-menu-${item.id}'),
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert, color: _textMuted),
                  onSelected: (choice) =>
                      choice == 'edit' ? onEdit() : onRemove(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit details')),
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        color: _textMuted,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: colour, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: _aqua),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 6), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Add / edit ──────────────────────────────────────────────────────────────

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({required this.onSave, this.existing});

  final InventoryItem? existing;
  final Future<InventoryItem> Function(Map<String, dynamic> fields) onSave;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.medicationName);
  late final _generic = TextEditingController(text: widget.existing?.genericName);
  late final _dosage = TextEditingController(text: widget.existing?.dosage);
  late final _sku = TextEditingController(text: widget.existing?.sku);
  late final _unit = TextEditingController(text: widget.existing?.unit);
  late final _packSize =
      TextEditingController(text: widget.existing?.packSize?.toString());
  late final _quantity = TextEditingController();
  late final _threshold = TextEditingController(
      text: widget.existing?.lowStockThreshold.toString() ?? '');
  late final _price = TextEditingController(
      text: widget.existing?.unitPrice?.toStringAsFixed(2));
  late final _supplier = TextEditingController(text: widget.existing?.supplier);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late DateTime? _expiry = widget.existing?.expiryDate;

  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    for (final c in [
      _name, _generic, _dosage, _sku, _unit, _packSize, _quantity,
      _threshold, _price, _supplier, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _blankToNull(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final expiry = _expiry;
    final fields = <String, dynamic>{
      'medication_name': _name.text.trim(),
      'generic_name': _blankToNull(_generic),
      'dosage': _blankToNull(_dosage),
      'sku': _blankToNull(_sku),
      'unit': _blankToNull(_unit),
      'pack_size': int.tryParse(_packSize.text.trim()),
      'low_stock_threshold': int.tryParse(_threshold.text.trim()) ?? 0,
      'unit_price': double.tryParse(_price.text.trim()),
      'expiry_date': expiry == null ? null : isoDay(expiry),
      'supplier': _blankToNull(_supplier),
      'notes': _blankToNull(_notes),
      if (_isNew) 'quantity_on_hand': int.tryParse(_quantity.text.trim()) ?? 0,
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave(fields);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageFor(error, 'It could not be saved.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? 'Add stock item' : 'Edit ${widget.existing!.medicationName}'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_name, 'Medication name *', key: 'name', validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Enter the medication name';
                  return null;
                }),
                _pair(
                  _field(_dosage, 'Strength and form', hint: '500mg tablet'),
                  _field(_generic, 'Generic name'),
                ),
                _pair(
                  _field(_sku, 'SKU / code'),
                  _field(_supplier, 'Supplier'),
                ),
                _pair(
                  _field(_unit, 'Unit', hint: 'tablets, ml, packs'),
                  _field(_packSize, 'Pack size',
                      number: true, validator: _wholeOrBlank),
                ),
                _pair(
                  _isNew
                      ? _field(_quantity, 'Starting quantity',
                          key: 'quantity', number: true, validator: _wholeOrBlank)
                      : _readOnly('On hand',
                          '${widget.existing!.quantityOnHand} (use Adjust stock)'),
                  _field(_threshold, 'Low stock at',
                      key: 'threshold', number: true, validator: _wholeOrBlank),
                ),
                _pair(
                  _field(_price, 'Unit price (R)',
                      decimal: true, validator: _amountOrBlank),
                  _expiryField(),
                ),
                _field(_notes, 'Notes', lines: 2),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: _outRed)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('inventory-save'),
          style: FilledButton.styleFrom(backgroundColor: _teal),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }

  Widget _pair(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? key,
    String? hint,
    bool number = false,
    bool decimal = false,
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key == null ? null : ValueKey('inventory-field-$key'),
        controller: controller,
        maxLines: lines,
        validator: validator,
        keyboardType: number || decimal
            ? TextInputType.numberWithOptions(decimal: decimal)
            : null,
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : decimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        child: Text(value, style: const TextStyle(color: _textMuted)),
      ),
    );
  }

  Widget _expiryField() {
    final expiry = _expiry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickExpiry,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Expiry date',
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: expiry == null
                ? const Icon(Icons.calendar_today_outlined, size: 18)
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _expiry = null),
                  ),
          ),
          child: Text(expiry == null ? 'None' : formatDay(expiry)),
        ),
      ),
    );
  }
}

String? _wholeOrBlank(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return int.tryParse(text) == null ? 'Whole number only' : null;
}

String? _amountOrBlank(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final amount = double.tryParse(text);
  return amount == null || amount < 0 ? 'Enter an amount like 45.50' : null;
}

// ─── Adjust stock ────────────────────────────────────────────────────────────

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.item, required this.onSave});

  final InventoryItem item;
  final Future<InventoryItem> Function(
      int delta, StockReason reason, String? notes) onSave;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  StockReason _reason = StockReason.restock;

  /// For a reason that can go either way: true adds stock.
  bool _adding = true;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _sign => switch (_reason.direction) {
        1 => 1,
        -1 => -1,
        _ => _adding ? 1 : -1,
      };

  int? get _delta {
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return null;
    return amount * _sign;
  }

  Future<void> _save() async {
    final delta = _delta;
    if (delta == null) {
      setState(() => _error = 'Enter how many units, more than 0');
      return;
    }
    if (widget.item.quantityOnHand + delta < 0) {
      setState(() => _error =
          'Only ${widget.item.quantityOnHand} on hand, so that many cannot be removed');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave(delta, _reason, _notes.text);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageFor(error, 'The stock could not be changed.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final delta = _delta;
    final after = delta == null ? null : widget.item.quantityOnHand + delta;
    return AlertDialog(
      title: Text('Adjust ${widget.item.medicationName}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<StockReason>(
              key: const ValueKey('inventory-reason'),
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Reason',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final reason in StockReason.values)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: (reason) {
                if (reason != null) setState(() => _reason = reason);
              },
            ),
            if (_reason.direction == 0) ...[
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add')),
                  ButtonSegment(value: false, label: Text('Remove')),
                ],
                selected: {_adding},
                onSelectionChanged: (s) => setState(() => _adding = s.first),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('inventory-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _sign > 0 ? 'Units to add' : 'Units to remove',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              after == null
                  ? 'On hand now: ${widget.item.quantityOnHand}'
                  : 'On hand: ${widget.item.quantityOnHand} → $after',
              key: const ValueKey('inventory-after'),
              style: TextStyle(
                color: after != null && after < 0 ? _outRed : _textMuted,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: _outRed)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('inventory-adjust-save'),
          style: FilledButton.styleFrom(backgroundColor: _teal),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

// ─── Formatting ──────────────────────────────────────────────────────────────

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "31 Jan 2027".
String formatDay(DateTime day) =>
    '${day.day} ${_months[day.month - 1]} ${day.year}';

/// "2027-01-31", as the DATE column takes it.
String isoDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// "R 1 250.00", with the space a South African reader expects.
String formatRand(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return 'R $whole.${parts[1]}';
}

String _messageFor(Object error, String fallback) {
  if (error is ApiException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}

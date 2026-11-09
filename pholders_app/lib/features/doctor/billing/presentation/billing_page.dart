import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/theme/app_colors.dart';
import '../data/billing_repository.dart';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart';

// ─── Status helpers ───────────────────────────────────────────────────────────
({Color bg, Color fg, String label}) _statusStyle(TxStatus s) => switch (s) {
  TxStatus.paid       => (bg: const Color(0xFFC4EDF0), fg: const Color(0xFF2E9FA5), label: 'Paid'),
  TxStatus.pending    => (bg: const Color(0xFFFFF0CE), fg: const Color(0xFFE0951A), label: 'Pending'),
  TxStatus.cancelled  => (bg: const Color(0xFFE2E4E4), fg: const Color(0xFF6C6C6C), label: 'Cancelled'),
  TxStatus.failed     => (bg: const Color(0xFFFFB4B4), fg: const Color(0xFFC62828), label: 'Failed'),
};

Color _dotColor(TxStatus s) => switch (s) {
  TxStatus.paid       => const Color(0xFF2E9FA5),
  TxStatus.pending    => const Color(0xFFF5A623),
  TxStatus.cancelled  => const Color(0xFF6C6C6C),
  TxStatus.failed     => const Color(0xFFE53935),
};

// ─── BillingPage ──────────────────────────────────────────────────────────────
/// The doctor's payments from patients, from /users/doctor/payments.
///
/// It used to show seven invented transactions, made-up totals (R88,200
/// earned), a Withdraw button that announced a R8,200 payout nobody made, and
/// a Cancel that changed only the row on screen. There is no payout or
/// doctor-side cancel on the backend, so those are gone rather than faked.
class BillingPage extends StatelessWidget {
  const BillingPage({super.key, this.repository});

  final BillingRepository? repository;

  @override
  Widget build(BuildContext context) {
    // The parent widget (e.g., ShellLayout) handles the layout.
    return _BillingBody(repository: repository ?? sl<BillingRepository>());
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _BillingBody extends StatefulWidget {
  const _BillingBody({required this.repository});

  final BillingRepository repository;

  @override
  State<_BillingBody> createState() => _BillingBodyState();
}

class _BillingBodyState extends State<_BillingBody> {
  final TextEditingController _searchController = TextEditingController();
  List<Transaction> _transactions = const [];
  List<Transaction> _filtered = const [];
  BillingSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.fetchSummary(),
        widget.repository.fetchPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as BillingSummary;
        _transactions = results[1] as List<Transaction>;
        _loading = false;
      });
      _onSearch();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _transactions
          : _transactions.where((tx) {
              return tx.patient.toLowerCase().contains(q) ||
                  tx.service.toLowerCase().contains(q) ||
                  tx.amount.toLowerCase().contains(q) ||
                  tx.date.toLowerCase().contains(q) ||
                  tx.method.toLowerCase().contains(q) ||
                  _statusStyle(tx.status).label.toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // As the patients page: white round the edge, the pale rounded panel
    // filling the rest, at least as tall as the window.
    return LayoutBuilder(builder: (context, c) {
      const outer = EdgeInsets.fromLTRB(31, 0, 38, 26);
      final minPanel = c.hasBoundedHeight ? c.maxHeight - outer.vertical : 0.0;
      return Material(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: outer,
          child: Container(
            constraints: BoxConstraints(minHeight: minPanel < 0 ? 0 : minPanel),
            padding: const EdgeInsets.fromLTRB(33, 30, 33, 26),
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.circular(32),
            ),
            child: _content(),
          ),
        ),
      );
    });
  }

  Widget _content() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Billing & Payments', style: TextStyle(fontSize: 30, color: Colors.black)),
            const Spacer(),
            if (!_loading)
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: _load,
              ),
          ]),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.activeTeal)),
            )
          else if (_error != null)
            _LoadError(message: _error!, onRetry: _load)
          else ...[
            _StatBox(summary: _summary!),
            const SizedBox(height: 32),
            _TransactionsHeader(controller: _searchController),
            const SizedBox(height: 22),
            const _ColumnHeaders(),
            const SizedBox(height: 14),
            _DataRowsBox(
              transactions: _filtered,
              searching: _searchController.text.trim().isNotEmpty,
            ),
          ],
        ],
    );
  }
}

const Color _panelBg = Color(0xFFE3F5F6);
const Color _aqua = Color(0xFF6DD0D8);

/// A white card on the design's aqua left edge.
class _EdgedCard extends StatelessWidget {
  const _EdgedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: _aqua, borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(color: Colors.white, child: child),
      ),
    );
  }
}

// ─── Load error ───────────────────────────────────────────────────────────────
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        const Text('Could not load your payments', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again', style: TextStyle(color: AppColors.activeTeal))),
      ]),
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox({required this.summary});

  final BillingSummary summary;

  String _count(int n, String one) => '$n ${n == 1 ? one : '${one}s'}';

  @override
  Widget build(BuildContext context) {
    return _EdgedCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatItem(icon: Icons.monetization_on_outlined, iconBg: AppColors.activeTeal.withValues(alpha: 0.12), iconColor: AppColors.activeTeal, label: 'Received', value: formatRand(summary.receivedAmount), sub: 'From paid consultations'),
                  _vDiv(),
                  _StatItem(icon: Icons.access_time_outlined, iconBg: const Color(0xFFFAEEDA), iconColor: const Color(0xFFBA7517), label: 'Pending Payments', value: formatRand(summary.pendingAmount), sub: 'Not paid yet'),
                  _vDiv(),
                  _StatItem(icon: Icons.check_circle_outline, iconBg: const Color(0xFFE1F5EE), iconColor: const Color(0xFF1D9E75), label: 'Completed Payments', value: '${summary.receivedCount}', sub: _count(summary.pendingCount, 'pending payment')),
                  _vDiv(),
                  _StatItem(icon: Icons.cancel_outlined, iconBg: const Color(0xFFF1EFE8), iconColor: const Color(0xFF5F5E5A), label: 'Cancelled or Failed', value: '${summary.cancelledCount + summary.failedCount}', sub: 'Not charged'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _vDiv() => Container(width: 1, color: const Color(0xFFD0D5D6), margin: const EdgeInsets.symmetric(vertical: 18));
}

class _StatItem extends StatelessWidget {

  const _StatItem({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.sub});
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 28, color: Colors.black)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Transactions header ──────────────────────────────────────────────────────
class _TransactionsHeader extends StatefulWidget {
  const _TransactionsHeader({required this.controller});
  final TextEditingController controller;

  @override
  State<_TransactionsHeader> createState() => _TransactionsHeaderState();
}

class _TransactionsHeaderState extends State<_TransactionsHeader> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFC4EDF0), shape: BoxShape.circle),
            child: const Icon(Icons.swap_horiz, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Transactions', style: TextStyle(fontSize: 20, color: Colors.black)),
        ]),
        SizedBox(
          width: 280,
          height: 40,
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search for transactions...',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () => widget.controller.clear(),
                      child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFC4EDF0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.activeTeal, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Column headers ───────────────────────────────────────────────────────────
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();
  static const _cols = ['Patient', 'Service', 'Amount', 'Date', 'Status', 'Actions'];
  static const _flex = [25, 19, 12, 13, 21, 10];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 24, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD3E6E7), width: 2)),
      ),
      child: Row(
        children: List.generate(_cols.length, (i) => Expanded(
          flex: _flex[i],
          child: Text(_cols[i], style: const TextStyle(fontSize: 13, color: Color(0xFF7C8B8D))),
        )),
      ),
    );
  }
}

// ─── Data rows box ────────────────────────────────────────────────────────────
class _DataRowsBox extends StatelessWidget {

  const _DataRowsBox({required this.transactions, required this.searching});
  final List<Transaction> transactions;

  /// Whether an empty list means "no match" rather than "no payments yet".
  final bool searching;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _EdgedCard(
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(children: [
            Icon(searching ? Icons.search_off_rounded : Icons.receipt_long_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(searching ? 'No transactions found' : 'No payments yet', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              searching
                  ? 'Try a different search term'
                  : 'Payments appear here when patients pay for appointments with you',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ]),
        ),
      ),
      );
    }

    return _EdgedCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: List.generate(
                transactions.length,
                (i) => _TxRow(
                  tx: transactions[i],
                  isLast: i == transactions.length - 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction row ──────────────────────────────────────────────────────────
class _TxRow extends StatefulWidget {

  const _TxRow({required this.tx, required this.isLast});
  final Transaction tx;
  final bool isLast;

  @override
  State<_TxRow> createState() => _TxRowState();
}

class _TxRowState extends State<_TxRow> {
  bool _hovered = false;

  // ── PDF Generation ─────────────────────────────────────────────────────────
  Future<void> _downloadReceiptPDF(Transaction tx) async {
    final statusInfo = _statusStyle(tx.status);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PHolders Healthcare',
                      style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2D9B8C)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payment Receipt',
                      style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: const pw.Border(bottom: const pw.BorderSide(color: PdfColors.grey400)),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Receipt Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfDetailRow('Transaction ID', tx.id),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Patient Name', tx.patient),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Service', tx.service),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Date', tx.date),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Paid by', tx.method),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Amount', tx.amount, isBold: true, color: const PdfColor.fromInt(0xFF2D9B8C)),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Status', statusInfo.label, isBold: true),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: const pw.Border(bottom: const pw.BorderSide(color: PdfColors.grey400)),
                ),
              ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for using PHolders Healthcare Platform',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'receipt_${tx.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      await downloadPdfFile(bytes, filename);
    } else {
      // Fallback for non-web platforms (e.g., save to device)
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  pw.Widget _pdfDetailRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  // ── Receipt dialog ─────────────────────────────────────────────────────────
  // Dialogs open on the root navigator, but this page sits in a ShellRoute
  // with its own. Each dialog closes itself through its own context: popping
  // with the page's context popped the page instead, and crashed.
  void _showReceipt(BuildContext context) {
    final tx = widget.tx;
    final statusInfo = _statusStyle(tx.status);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  color: AppColors.activeTeal,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(children: [
                  const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('Payment Receipt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('PHolders Healthcare', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ]),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _receiptRow('Transaction ID', tx.id),
                    _receiptDivider(),
                    _receiptRow('Patient', tx.patient),
                    _receiptDivider(),
                    _receiptRow('Service', tx.service),
                    _receiptDivider(),
                    _receiptRow('Date', tx.date),
                    _receiptDivider(),
                    _receiptRow('Paid by', tx.method),
                    _receiptDivider(),
                    _receiptRow('Amount', tx.amount, valueColor: AppColors.activeTeal, valueBold: true),
                    _receiptDivider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: statusInfo.bg, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: _dotColor(tx.status), shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(statusInfo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusInfo.fg)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Copy to clipboard button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final receiptText =
                              'PHolders Healthcare Receipt\n'
                              '─────────────────────────\n'
                              'Transaction ID : ${tx.id}\n'
                              'Patient        : ${tx.patient}\n'
                              'Service        : ${tx.service}\n'
                              'Date           : ${tx.date}\n'
                              'Paid by        : ${tx.method}\n'
                              'Amount         : ${tx.amount}\n'
                              'Status         : ${statusInfo.label}\n'
                              '─────────────────────────';
                          Clipboard.setData(ClipboardData(text: receiptText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Receipt copied to clipboard'),
                              backgroundColor: AppColors.activeTeal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy to Clipboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.activeTeal,
                          side: const BorderSide(color: AppColors.activeTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Download PDF button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          try {
                            await _downloadReceiptPDF(tx);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Could not create the receipt PDF: $e'),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('Receipt PDF downloaded'),
                              backgroundColor: AppColors.activeTeal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download as PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandTeal.withValues(alpha: 0.9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.activeTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close'),
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

  Widget _receiptRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptDivider() => const Divider(color: AppColors.divider, height: 1);

  // ── View Details dialog ────────────────────────────────────────────────────
  void _showDetails(BuildContext context) {
    final tx = widget.tx;
    final statusInfo = _statusStyle(tx.status);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.activeTeal,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              tx.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.patient,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Transaction Details',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusInfo.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Transaction ID
                      _detailsSection(
                        icon: Icons.confirmation_number,
                        iconColor: AppColors.activeTeal,
                        label: 'Transaction ID',
                        value: tx.id,
                      ),
                      const SizedBox(height: 16),

                      // Patient Info
                      _detailsSection(
                        icon: Icons.person,
                        iconColor: AppColors.activeTeal,
                        label: 'Patient Name',
                        value: tx.patient,
                      ),
                      const SizedBox(height: 16),

                      // Service
                      _detailsSection(
                        icon: Icons.medical_services_outlined,
                        iconColor: AppColors.activeTeal,
                        label: 'Service',
                        value: tx.service,
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      _detailsSection(
                        icon: Icons.attach_money,
                        iconColor: AppColors.activeTeal,
                        label: 'Amount',
                        value: tx.amount,
                        valueStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.activeTeal,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _detailsSection(
                        icon: Icons.calendar_today,
                        iconColor: AppColors.activeTeal,
                        label: 'Date',
                        value: tx.date,
                      ),
                      const SizedBox(height: 16),

                      // How the patient paid
                      _detailsSection(
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.activeTeal,
                        label: 'Paid by',
                        value: tx.method,
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusInfo.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusInfo.fg.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _dotColor(tx.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statusInfo.fg.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    statusInfo.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: statusInfo.fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showReceipt(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.activeTeal,
                                side: const BorderSide(color: AppColors.activeTeal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 16),
                                  SizedBox(width: 6),
                                  Text('Receipt'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.activeTeal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Action menu ────────────────────────────────────────────────────────────
  void _showMenu(BuildContext context) {
    final tx = widget.tx;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            // Transaction info pill
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFD9F5F5),
                    child: Text(tx.initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF0F6E56))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tx.patient, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('${tx.service}  ·  ${tx.amount}  ·  ${tx.date}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // View Details
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.activeTeal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.info_outline, color: AppColors.activeTeal, size: 18),
              ),
              title: const Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('See full transaction information', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _showDetails(context);
              },
            ),

            // View receipt
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.activeTeal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.activeTeal, size: 18),
              ),
              title: const Text('Download Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('View and copy transaction receipt', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _showReceipt(context);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(widget.tx.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.brandTeal.withValues(alpha: 0.04) : Colors.transparent,
          border: widget.isLast ? null : const Border(bottom: const BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 25,
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FAFA),
                    shape: BoxShape.circle,
                    border: Border.all(color: _aqua, width: 1.5),
                  ),
                  child: Text(widget.tx.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2E9FA5))),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(widget.tx.patient, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(flex: 19, child: Text(widget.tx.service, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(flex: 12, child: Text(widget.tx.amount,  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(flex: 13, child: Text(widget.tx.date,    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(
              flex: 21,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 108),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _dotColor(widget.tx.status), shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(style.label, style: TextStyle(fontSize: 13, color: style.fg)),
                  ]),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                onPressed: () => _showMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
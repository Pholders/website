import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../main.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../../../../shared/widgets/app_top_navbar.dart';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart';

// ─── Transaction model ────────────────────────────────────────────────────────
enum TxStatus { paid, pending, cancelled, refund, processing }

class Transaction {
  final String id;
  final String patient;
  final String initials;
  final String service;
  final String amount;
  final String date;
  final TxStatus status;

  const Transaction({
    required this.id,
    required this.patient,
    required this.initials,
    required this.service,
    required this.amount,
    required this.date,
    required this.status,
  });

  Transaction copyWith({TxStatus? status}) => Transaction(
    id: id,
    patient: patient,
    initials: initials,
    service: service,
    amount: amount,
    date: date,
    status: status ?? this.status,
  );
}

final _initialTransactions = [
  Transaction(id: 'TXN-001', patient: 'Maria Wilson',   initials: 'MW', service: 'Consultation', amount: 'R200', date: '05 May', status: TxStatus.paid),
  Transaction(id: 'TXN-002', patient: 'James Mokoena',  initials: 'JM', service: 'Chemotherapy',  amount: 'R450', date: '03 May', status: TxStatus.pending),
  Transaction(id: 'TXN-003', patient: 'Sarah Dlamini',  initials: 'SD', service: 'Consultation',  amount: 'R200', date: '03 May', status: TxStatus.cancelled),
  Transaction(id: 'TXN-004', patient: 'John Nkosi',     initials: 'JN', service: 'X-Ray',         amount: 'R100', date: '02 May', status: TxStatus.paid),
  Transaction(id: 'TXN-005', patient: 'Thandi Khumalo', initials: 'TK', service: 'Consultation',  amount: 'R80',  date: '01 May', status: TxStatus.refund),
  Transaction(id: 'TXN-006', patient: 'Peter Sithole',  initials: 'PS', service: 'Blood Test',    amount: 'R200', date: '30 Apr', status: TxStatus.processing),
  Transaction(id: 'TXN-007', patient: 'Lisa Mahlangu',  initials: 'LM', service: 'Consultation',  amount: 'R200', date: '29 Apr', status: TxStatus.paid),
];

// ─── Status helpers ───────────────────────────────────────────────────────────
({Color bg, Color fg, String label}) _statusStyle(TxStatus s) => switch (s) {
  TxStatus.paid       => (bg: const Color(0xFFE1F5EE), fg: const Color(0xFF0F6E56), label: 'Paid'),
  TxStatus.pending    => (bg: const Color(0xFFFAEEDA), fg: const Color(0xFF854F0B), label: 'Pending'),
  TxStatus.cancelled  => (bg: const Color(0xFFF1EFE8), fg: const Color(0xFF5F5E5A), label: 'Cancelled'),
  TxStatus.refund     => (bg: const Color(0xFFFCEBEB), fg: const Color(0xFFA32D2D), label: 'Refund'),
  TxStatus.processing => (bg: const Color(0xFFE6F1FB), fg: const Color(0xFF185FA5), label: 'Processing'),
};

Color _dotColor(TxStatus s) => switch (s) {
  TxStatus.paid       => const Color(0xFF1D9E75),
  TxStatus.pending    => const Color(0xFFBA7517),
  TxStatus.cancelled  => const Color(0xFF888780),
  TxStatus.refund     => const Color(0xFFE24B4A),
  TxStatus.processing => const Color(0xFF378ADD),
};

// ─── BillingPage ──────────────────────────────────────────────────────────────
class BillingPage extends StatelessWidget {
  const BillingPage({super.key});
  static const String _role = 'doctor';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            AppSidebar(role: _role, collapsed: false),
            VerticalDivider(width: 0.5, thickness: 0.5, color: AppColors.divider),
            Expanded(
              child: Column(
                children: [
                  AppTopNavbar(role: _role),
                  const Expanded(child: _BillingBody()),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(child: AppSidebar(role: _role, collapsed: false)),
      body: Builder(
        builder: (ctx) => Column(
          children: [
            AppTopNavbar(role: _role, onMenuTap: () => Scaffold.of(ctx).openDrawer()),
            const Expanded(child: _BillingBody()),
          ],
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _BillingBody extends StatefulWidget {
  const _BillingBody();

  @override
  State<_BillingBody> createState() => _BillingBodyState();
}

class _BillingBodyState extends State<_BillingBody> {
  final TextEditingController _searchController = TextEditingController();
  late List<Transaction> _transactions;
  List<Transaction> _filtered = [];

  @override
  void initState() {
    super.initState();
    _transactions = List.from(_initialTransactions);
    _filtered = _transactions;
    _searchController.addListener(_onSearch);
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
                  _statusStyle(tx.status).label.toLowerCase().contains(q);
            }).toList();
    });
  }

  void _cancelTransaction(String id) {
    setState(() {
      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _transactions[idx] = _transactions[idx].copyWith(status: TxStatus.cancelled);
      }
      _onSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Billing & Payments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _WithdrawButton(),
          const SizedBox(height: 18),
          const _StatBox(),
          const SizedBox(height: 24),
          _TransactionsHeader(controller: _searchController),
          const SizedBox(height: 10),
          const _ColumnHeaders(),
          const SizedBox(height: 6),
          _DataRowsBox(
            transactions: _filtered,
            onCancel: _cancelTransaction,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Withdraw button ──────────────────────────────────────────────────────────
class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Withdraw Funds'),
          content: const Text('Your withdrawal request of R8,200 has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: AppColors.activeTeal)),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: AppColors.activeTeal, borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_circle_up_outlined, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: AppColors.brandTeal,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatItem(icon: Icons.monetization_on_outlined, iconBg: AppColors.activeTeal.withOpacity(0.12), iconColor: AppColors.activeTeal, label: 'Total Earnings',     value: 'R88,200', sub: '+2.5% Learn more', subColor: const Color(0xFF1D9E75)),
                  _vDiv(),
                  _StatItem(icon: Icons.account_balance_wallet_outlined, iconBg: AppColors.activeTeal.withOpacity(0.12), iconColor: AppColors.activeTeal, label: 'Available Balance', value: 'R8,200',  sub: 'Ready to withdraw'),
                  _vDiv(),
                  _StatItem(icon: Icons.access_time_outlined, iconBg: const Color(0xFFFAEEDA), iconColor: const Color(0xFFBA7517), label: 'Pending Payments',   value: 'R3,400',  sub: 'In progress'),
                  _vDiv(),
                  _StatItem(icon: Icons.check_circle_outline,  iconBg: const Color(0xFFE1F5EE), iconColor: const Color(0xFF1D9E75), label: 'Completed Payments', value: '42',      sub: 'Transactions'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _vDiv() => Container(width: 0.5, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 16));
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final Color? subColor;

  const _StatItem({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.sub, this.subColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 18)),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(fontSize: 10, color: subColor ?? AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Transactions header ──────────────────────────────────────────────────────
class _TransactionsHeader extends StatefulWidget {
  final TextEditingController controller;
  const _TransactionsHeader({required this.controller});

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
          Icon(Icons.swap_horiz, color: AppColors.activeTeal, size: 18),
          const SizedBox(width: 8),
          Text('Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ]),
        SizedBox(
          width: 220,
          height: 36,
          child: TextField(
            controller: widget.controller,
            style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search for transactions...',
              hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
              prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () => widget.controller.clear(),
                      child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.brandTeal.withOpacity(0.12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.activeTeal, width: 1.5)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: List.generate(_cols.length, (i) => Expanded(
          flex: _flex[i],
          child: Text(_cols[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
        )),
      ),
    );
  }
}

// ─── Data rows box ────────────────────────────────────────────────────────────
class _DataRowsBox extends StatelessWidget {
  final List<Transaction> transactions;
  final void Function(String id) onCancel;

  const _DataRowsBox({required this.transactions, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Center(
          child: Column(children: [
            Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('No transactions found', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text('Try a different search term', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: AppColors.brandTeal,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              children: List.generate(
                transactions.length,
                (i) => _TxRow(
                  tx: transactions[i],
                  isLast: i == transactions.length - 1,
                  onCancel: onCancel,
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
  final Transaction tx;
  final bool isLast;
  final void Function(String id) onCancel;

  const _TxRow({required this.tx, required this.isLast, required this.onCancel});

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
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2D9B8C)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payment Receipt',
                      style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
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
                  _pdfDetailRow('Amount', tx.amount, isBold: true, color: PdfColor.fromInt(0xFF2D9B8C)),
                  pw.SizedBox(height: 10),
                  _pdfDetailRow('Status', statusInfo.label, isBold: true),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                ),
              ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for using PHolders Healthcare Platform',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
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
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  pw.Widget _pdfDetailRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
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
  void _showReceipt(BuildContext context) {
    final tx = widget.tx;
    final statusInfo = _statusStyle(tx.status);

    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                decoration: BoxDecoration(
                  color: AppColors.activeTeal,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(children: [
                  const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('Payment Receipt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('PHolders Healthcare', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
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
                    _receiptRow('Amount', tx.amount, valueColor: AppColors.activeTeal, valueBold: true),
                    _receiptDivider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                          side: BorderSide(color: AppColors.activeTeal),
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
                          Navigator.pop(context);
                          await _downloadReceiptPDF(tx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Receipt PDF ready for download'),
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
                          backgroundColor: AppColors.brandTeal.withOpacity(0.9),
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
                        onPressed: () => Navigator.pop(context),
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
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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

  Widget _receiptDivider() => Divider(color: AppColors.rowDivider, height: 1);

  // ── View Details dialog ────────────────────────────────────────────────────
  void _showDetails(BuildContext context) {
    final tx = widget.tx;
    final statusInfo = _statusStyle(tx.status);

    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                  decoration: BoxDecoration(
                    color: AppColors.activeTeal,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
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
                                    color: Colors.white.withOpacity(0.8),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
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
                        valueStyle: TextStyle(
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

                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusInfo.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusInfo.fg.withOpacity(0.3)),
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
                                      color: statusInfo.fg.withOpacity(0.7),
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
                                Navigator.pop(context);
                                _showReceipt(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.activeTeal,
                                side: BorderSide(color: AppColors.activeTeal),
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
                              onPressed: () => Navigator.pop(context),
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
            color: iconColor.withOpacity(0.12),
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
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    TextStyle(
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

  // ── Cancel confirmation dialog ─────────────────────────────────────────────
  void _confirmCancel(BuildContext context) {
    final tx = widget.tx;

    // Already cancelled — nothing to do
    if (tx.status == TxStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This transaction is already cancelled'),
          backgroundColor: AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Cancel Transaction', style: TextStyle(fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this transaction?', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _dialogInfoRow('Patient', tx.patient),
                  const SizedBox(height: 4),
                  _dialogInfoRow('Service', tx.service),
                  const SizedBox(height: 4),
                  _dialogInfoRow('Amount', tx.amount),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel(tx.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction ${tx.id} has been cancelled'),
                  backgroundColor: Colors.red.shade400,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Action menu ────────────────────────────────────────────────────────────
  void _showMenu(BuildContext context) {
    final tx = widget.tx;
    final canCancel = tx.status != TxStatus.cancelled && tx.status != TxStatus.refund;

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
                      Text(tx.patient, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('${tx.service}  ·  ${tx.amount}  ·  ${tx.date}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                decoration: BoxDecoration(color: AppColors.activeTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.info_outline, color: AppColors.activeTeal, size: 18),
              ),
              title: const Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text('See full transaction information', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _showDetails(context);
              },
            ),

            // View receipt
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.activeTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.receipt_long_outlined, color: AppColors.activeTeal, size: 18),
              ),
              title: const Text('Download Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text('View and copy transaction receipt', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _showReceipt(context);
              },
            ),

            // Cancel
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: canCancel ? const Color(0xFFFCEBEB) : AppColors.rowDivider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.cancel_outlined, color: canCancel ? Colors.red : AppColors.textMuted, size: 18),
              ),
              title: Text(
                'Cancel Transaction',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: canCancel ? AppColors.textPrimary : AppColors.textMuted),
              ),
              subtitle: Text(
                canCancel ? 'Mark this transaction as cancelled' : 'Already ${_statusStyle(tx.status).label.toLowerCase()}',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              onTap: canCancel
                  ? () {
                      Navigator.pop(context);
                      _confirmCancel(context);
                    }
                  : null,
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
          color: _hovered ? AppColors.brandTeal.withOpacity(0.04) : Colors.transparent,
          border: widget.isLast ? null : Border(bottom: BorderSide(color: AppColors.rowDivider, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 25,
              child: Row(children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFD9F5F5),
                  child: Text(widget.tx.initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF0F6E56))),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(widget.tx.patient, style: TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(flex: 19, child: Text(widget.tx.service, style: TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(flex: 12, child: Text(widget.tx.amount,  style: TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(flex: 13, child: Text(widget.tx.date,    style: TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Expanded(
              flex: 21,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _dotColor(widget.tx.status), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(style.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: style.fg)),
                  ]),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: IconButton(
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onPressed: () => _showMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
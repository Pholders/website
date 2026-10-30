import '../../../../core/network/api_client.dart';

/// Where a payment stands, as the backend's payments table records it.
enum TxStatus { paid, pending, cancelled, failed }

TxStatus _statusFrom(Object? value) => switch (value?.toString()) {
      'completed' => TxStatus.paid,
      'cancelled' => TxStatus.cancelled,
      'failed' => TxStatus.failed,
      _ => TxStatus.pending,
    };

/// Postgres DECIMAL columns arrive as strings ("450.00").
double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

/// R1,350 or R450.50: whole rands without cents, thousands separated.
String formatRand(double amount) {
  final whole = amount.truncate();
  final cents = ((amount - whole) * 100).round();
  final digits = whole.abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return cents == 0
      ? 'R$sign$grouped'
      : 'R$sign$grouped.${cents.toString().padLeft(2, '0')}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')} ${_months[local.month - 1]} ${local.year}';
}

String _titleCase(String text) => text
    .split(RegExp(r'[_\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

/// One patient payment for one of this doctor's appointments.
class Transaction {
  const Transaction({
    required this.id,
    required this.patient,
    required this.initials,
    required this.service,
    required this.amount,
    required this.date,
    required this.status,
    required this.method,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final patient = (json['patientName']?.toString().trim().isNotEmpty ?? false)
        ? json['patientName'].toString().trim()
        : 'Patient';
    final initials = patient
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    // The visit date, not when the payment row was written.
    final date = DateTime.tryParse('${json['appointmentDate'] ?? json['createdAt']}');
    return Transaction(
      id: 'PAY-${json['paymentId']}',
      patient: patient,
      initials: initials,
      service: _titleCase(json['service']?.toString() ?? 'consultation'),
      amount: formatRand(_number(json['amount'])),
      date: _formatDate(date),
      status: _statusFrom(json['paymentStatus']),
      method: switch (json['paymentMethod']?.toString()) {
        'cash_on_arrival' => 'Cash at the practice',
        'stripe' => 'Card (online)',
        'medical_aid' => 'Medical aid',
        final other? => _titleCase(other),
        null => '—',
      },
    );
  }

  final String id;
  final String patient;
  final String initials;
  final String service;
  final String amount;
  final String date;
  final TxStatus status;

  /// How the patient paid: cash at the practice, card, or medical aid.
  final String method;
}

/// The doctor's totals across every payment, whatever page is shown.
class BillingSummary {
  const BillingSummary({
    required this.receivedAmount,
    required this.receivedCount,
    required this.pendingAmount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.failedCount,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) => BillingSummary(
        receivedAmount: _number(json['completedAmount']),
        receivedCount: _number(json['completedPayments']).toInt(),
        pendingAmount: _number(json['pendingAmount']),
        pendingCount: _number(json['pendingPayments']).toInt(),
        cancelledCount: _number(json['cancelledPayments']).toInt(),
        failedCount: _number(json['failedPayments']).toInt(),
      );

  final double receivedAmount;
  final int receivedCount;
  final double pendingAmount;
  final int pendingCount;
  final int cancelledCount;
  final int failedCount;
}

/// The signed-in doctor's payments, from /users/doctor/payments.
class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  // ApiClient hands back the response's `data` object itself.
  Future<BillingSummary> fetchSummary() async {
    return BillingSummary.fromJson(
        await _api.get('/users/doctor/payments/summary'));
  }

  /// Newest first. The server caps a page at 200.
  Future<List<Transaction>> fetchPayments({int limit = 200}) async {
    final data = await _api.get(
      '/users/doctor/payments',
      queryParameters: {'limit': limit},
    );
    final rows = data['payments'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

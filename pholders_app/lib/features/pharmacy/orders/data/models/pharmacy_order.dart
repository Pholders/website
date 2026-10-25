import 'package:equatable/equatable.dart';

/// Where an order sits in the pharmacy's workflow.
///
/// These are the backend's own values. `outForDelivery` deliberately has no
/// entry: the state machine has no such status, only a fulfilment type.
enum OrderStatus {
  pending,
  accepted,
  awaitingClaim,
  claimApproved,
  claimRejected,
  preparing,
  ready,
  pickedUp,
  cancelled,
  rejected,
  unknown,
}

extension OrderStatusX on OrderStatus {
  /// The value the backend expects back on a transition.
  String get wireName => switch (this) {
        OrderStatus.pending => 'pending',
        OrderStatus.accepted => 'accepted',
        OrderStatus.awaitingClaim => 'awaiting_claim',
        OrderStatus.claimApproved => 'claim_approved',
        OrderStatus.claimRejected => 'claim_rejected',
        OrderStatus.preparing => 'preparing',
        OrderStatus.ready => 'ready',
        OrderStatus.pickedUp => 'picked_up',
        OrderStatus.cancelled => 'cancelled',
        OrderStatus.rejected => 'rejected',
        OrderStatus.unknown => 'unknown',
      };

  String get label => switch (this) {
        OrderStatus.pending => 'New',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.awaitingClaim => 'Awaiting claim',
        OrderStatus.claimApproved => 'Claim approved',
        OrderStatus.claimRejected => 'Claim rejected',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.pickedUp => 'Collected',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.rejected => 'Rejected',
        OrderStatus.unknown => 'Unknown',
      };

  /// Nothing more happens to an order in these states.
  bool get isTerminal =>
      this == OrderStatus.pickedUp ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.rejected;
}

/// An order placed against a prescription at this pharmacy.
///
/// Shape from `GET /orders/pharmacy/queue`, which returns raw snake_case
/// columns plus the patient's name and the script reference.
class PharmacyOrder extends Equatable {
  const PharmacyOrder({
    required this.id,
    required this.status,
    this.prescriptionNumber,
    this.patientName,
    this.patientPhone,
    this.paymentType,
    this.fulfillmentType,
    this.totalAmount,
    this.patientResponsibility,
    this.pharmacyNotes,
    this.rejectionReason,
    this.createdAt,
  });

  factory PharmacyOrder.fromJson(Map<String, dynamic> json) {
    final first = _str(json['patient_first_name']);
    final last = _str(json['patient_last_name']);
    final name = [first, last].whereType<String>().join(' ').trim();

    return PharmacyOrder(
      id: _int(json['id']) ?? 0,
      status: _statusFrom(_str(json['status'])),
      prescriptionNumber: _str(json['prescription_number']),
      patientName: name.isEmpty ? null : name,
      patientPhone: _str(json['patient_phone']),
      paymentType: _str(json['payment_type']),
      fulfillmentType: _str(json['fulfillment_type']),
      totalAmount: _double(json['total_amount']),
      patientResponsibility: _double(json['patient_responsibility']),
      pharmacyNotes: _str(json['pharmacy_notes']),
      rejectionReason: _str(json['rejection_reason']),
      createdAt: DateTime.tryParse(_str(json['created_at']) ?? ''),
    );
  }

  final int id;
  final OrderStatus status;
  final String? prescriptionNumber;
  final String? patientName;
  final String? patientPhone;

  /// 'self' or 'medical_aid'.
  final String? paymentType;

  /// 'pickup' or 'delivery'.
  final String? fulfillmentType;

  final double? totalAmount;
  final double? patientResponsibility;
  final String? pharmacyNotes;
  final String? rejectionReason;
  final DateTime? createdAt;

  /// "#10234", the reference a pharmacy reads out.
  String get reference => '#$id';

  /// "R450.00", or a dash before the pharmacy has quoted.
  String get totalLabel =>
      totalAmount == null ? '—' : 'R${totalAmount!.toStringAsFixed(2)}';

  /// What the patient still owes, which is the whole total on a self-pay
  /// order and only the gap on a medical aid one.
  String get dueLabel => patientResponsibility == null
      ? totalLabel
      : 'R${patientResponsibility!.toStringAsFixed(2)}';

  bool get isMedicalAid => paymentType == 'medical_aid';
  bool get isDelivery => fulfillmentType == 'delivery';

  /// The next status the pharmacy would move this to, or null when the order
  /// is finished or waiting on somebody else.
  OrderStatus? get nextStatus => switch (status) {
        OrderStatus.accepted => OrderStatus.preparing,
        OrderStatus.claimApproved => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.pickedUp,
        _ => null,
      };

  @override
  List<Object?> get props => [id, status, totalAmount, patientResponsibility];

  static OrderStatus _statusFrom(String? raw) => switch (raw) {
        'pending' => OrderStatus.pending,
        'accepted' => OrderStatus.accepted,
        'awaiting_claim' => OrderStatus.awaitingClaim,
        'claim_approved' => OrderStatus.claimApproved,
        'claim_rejected' => OrderStatus.claimRejected,
        'preparing' => OrderStatus.preparing,
        'ready' => OrderStatus.ready,
        'picked_up' => OrderStatus.pickedUp,
        'cancelled' => OrderStatus.cancelled,
        'rejected' => OrderStatus.rejected,
        _ => OrderStatus.unknown,
      };

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static double? _double(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }
}

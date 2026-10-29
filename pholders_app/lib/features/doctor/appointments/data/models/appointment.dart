import 'package:equatable/equatable.dart';

/// An appointment assigned to the signed-in doctor.
///
/// Shape comes from `GET /users/doctor/appointments`, which returns an
/// explicitly mapped camelCase object (unlike most endpoints, which return
/// raw snake_case database rows).
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.patientName,
    this.patientId,
    this.patientEmail,
    this.patientPhone,
    this.date,
    this.timePeriod,
    this.timeSlot,
    this.reason,
    this.consultationFee,
    this.status,
    this.doctorAccepted = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: _asInt(json['id']) ?? 0,
      patientName: _asString(json['patientName']) ?? 'Unknown patient',
      patientId: _asInt(json['patientId']),
      patientEmail: _asString(json['patientEmail']),
      patientPhone: _asString(json['patientPhone']),
      date: DateTime.tryParse(_asString(json['appointmentDate']) ?? ''),
      timePeriod: _asString(json['timePeriod']),
      timeSlot: _asString(json['timeSlot']),
      reason: _asString(json['reason']),
      consultationFee: _asDouble(json['consultationFee']),
      status: _asString(json['status']),
      doctorAccepted: json['doctorAccepted'] == true,
    );
  }

  final int id;
  final String patientName;

  /// The patient's own id, as opposed to the appointment's. Null on a backend
  /// that predates it being returned — nothing may assume it is present.
  final int? patientId;

  final String? patientEmail;
  final String? patientPhone;
  final DateTime? date;

  /// 'morning' | 'afternoon' | 'evening' | 'night'.
  final String? timePeriod;

  /// Start of the booked slot, as "HH:mm".
  final String? timeSlot;
  final String? reason;
  final double? consultationFee;

  /// 'pending_payment' | 'scheduled' | 'rescheduled' | 'completed' |
  /// 'cancelled'. 'rescheduled' is a paid appointment that was moved.
  final String? status;
  final bool doctorAccepted;

  /// The hour of the booked slot, used to position the card on the day grid.
  /// Falls back to 9am when the slot is missing or malformed.
  int get hour {
    final slot = timeSlot;
    if (slot == null) return 9;
    return int.tryParse(slot.split(':').first) ?? 9;
  }

  /// "09:00-10:00" — consultations are booked in one-hour blocks.
  String get timeRange {
    final slot = timeSlot;
    if (slot == null) return '';
    return '$slot-${(hour + 1).toString().padLeft(2, '0')}:00';
  }

  /// "26 Apr 2026", matching the design's date format.
  String get formattedDate {
    final d = date;
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// A visit that is over: completed, or its day has gone by. Drives the
  /// Past visits tab; everything else is a future visit.
  bool isPastAt(DateTime now) {
    if (status == 'completed') return true;
    final d = date?.toLocal();
    if (d == null) return false;
    return DateTime(d.year, d.month, d.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Paid and not yet seen: the only state the server lets a doctor complete.
  bool get canComplete => status == 'scheduled' || status == 'rescheduled';

  /// A human label for the status badge.
  ///
  /// A finished or cancelled appointment says so even if the doctor accepted
  /// it first. Checking acceptance first left a completed consultation
  /// reading "Accepted", so completing one looked like it had done nothing.
  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
    }
    if (doctorAccepted) return 'Accepted';
    switch (status) {
      case 'pending_payment':
        return 'Awaiting payment';
      case 'scheduled':
        return 'Scheduled';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status ?? 'Unknown';
    }
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null null' ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props =>
      [id, patientName, patientId, date, timeSlot, status, doctorAccepted];
}

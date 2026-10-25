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

  /// 'pending_payment' | 'scheduled' | 'completed' | 'cancelled'.
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

  /// A human label for the status badge.
  String get statusLabel {
    if (doctorAccepted) return 'Accepted';
    switch (status) {
      case 'pending_payment':
        return 'Awaiting payment';
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
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

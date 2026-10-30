import '../../appointments/data/models/appointment.dart';

/// What the doctor's dashboard shows, worked out from their own appointments.
///
/// Everything here comes from the one list the Appointments and Patients
/// pages already load, so the three pages always agree.

bool _cancelled(Appointment a) => a.status == 'cancelled';

DateTime? _day(Appointment a) {
  final d = a.date?.toLocal();
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Minutes after midnight the slot starts, for ordering and placing cards.
int startMinutes(Appointment a) {
  final parts = (a.timeSlot ?? '').split(':');
  final hour = int.tryParse(parts.first) ?? a.hour;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return hour * 60 + minute;
}

/// Today's appointments that are still on, earliest first.
List<Appointment> todaysAppointments(List<Appointment> all, DateTime now) {
  final today = _dayOf(now);
  return all
      .where((a) => !_cancelled(a) && _day(a) == today)
      .toList()
    ..sort((a, b) => startMinutes(a).compareTo(startMinutes(b)));
}

/// The first appointment after today, to say what is coming when today is
/// empty.
Appointment? nextAppointmentAfterToday(List<Appointment> all, DateTime now) {
  final today = _dayOf(now);
  final ahead = all.where((a) {
    final d = _day(a);
    return !_cancelled(a) && d != null && d.isAfter(today);
  }).toList()
    ..sort((a, b) {
      final byDay = _day(a)!.compareTo(_day(b)!);
      return byDay != 0 ? byDay : startMinutes(a).compareTo(startMinutes(b));
    });
  return ahead.isEmpty ? null : ahead.first;
}

/// Bookings the doctor still has to accept: paid, not yet accepted, and not
/// in the past.
int awaitingAcceptance(List<Appointment> all, DateTime now) {
  final today = _dayOf(now);
  return all.where((a) {
    final d = _day(a);
    return !a.doctorAccepted &&
        (a.status == 'scheduled' || a.status == 'rescheduled') &&
        (d == null || !d.isBefore(today));
  }).length;
}

/// Appointments (not cancelled) in the calendar month containing [month].
int appointmentsInMonth(List<Appointment> all, DateTime month) => all.where((a) {
      final d = _day(a);
      return !_cancelled(a) &&
          d != null &&
          d.year == month.year &&
          d.month == month.month;
    }).length;

/// "+12%" or "-5%" against last month, or null when last month had none and
/// a percentage would be meaningless.
String? changeVersusLastMonth(List<Appointment> all, DateTime now) {
  final current = appointmentsInMonth(all, now);
  final previous = appointmentsInMonth(all, DateTime(now.year, now.month - 1));
  if (previous == 0) return null;
  final change = ((current - previous) / previous * 100).round();
  return '${change >= 0 ? '+' : ''}$change%';
}

/// Patients whose first booking with this doctor falls in [now]'s month.
int newPatientsThisMonth(List<Appointment> all, DateTime now) {
  final first = <int, DateTime>{};
  for (final a in all) {
    final id = a.patientId;
    final d = _day(a);
    if (id == null || d == null) continue;
    final seen = first[id];
    if (seen == null || d.isBefore(seen)) first[id] = d;
  }
  return first.values
      .where((d) => d.year == now.year && d.month == now.month)
      .length;
}

/// The most recent appointment day on or before today for one patient.
DateTime? lastVisit(List<Appointment> all, int patientId, DateTime now) {
  final today = _dayOf(now);
  DateTime? latest;
  for (final a in all) {
    if (a.patientId != patientId || _cancelled(a)) continue;
    final d = _day(a);
    if (d == null || d.isAfter(today)) continue;
    if (latest == null || d.isAfter(latest)) latest = d;
  }
  return latest;
}

enum TrendPeriod { weekly, monthly, yearly }

/// One bar group of the activity chart.
class TrendBucket {
  const TrendBucket(this.label, this.appointments, this.patients);
  final String label;
  final int appointments;

  /// Distinct patients among those appointments.
  final int patients;
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Appointments and patients per day (last 7 days), month (last 12) or year
/// (last 5), oldest first, ending with the current one.
List<TrendBucket> activityTrend(
  List<Appointment> all,
  TrendPeriod period,
  DateTime now,
) {
  final today = _dayOf(now);
  final List<(String, bool Function(DateTime))> slots = switch (period) {
    TrendPeriod.weekly => [
        for (var i = 6; i >= 0; i--)
          () {
            final day = DateTime(today.year, today.month, today.day - i);
            return (_weekdayNames[day.weekday - 1], (DateTime d) => d == day);
          }(),
      ],
    TrendPeriod.monthly => [
        for (var i = 11; i >= 0; i--)
          () {
            final m = DateTime(today.year, today.month - i);
            return (
              _monthNames[m.month - 1],
              (DateTime d) => d.year == m.year && d.month == m.month,
            );
          }(),
      ],
    TrendPeriod.yearly => [
        for (var i = 4; i >= 0; i--)
          ('${today.year - i}', (DateTime d) => d.year == today.year - i),
      ],
  };

  return [
    for (final (label, matches) in slots)
      () {
        final hits = all.where((a) {
          final d = _day(a);
          return !_cancelled(a) && d != null && matches(d);
        });
        return TrendBucket(
          label,
          hits.length,
          hits.map((a) => a.patientId).whereType<int>().toSet().length,
        );
      }(),
  ];
}

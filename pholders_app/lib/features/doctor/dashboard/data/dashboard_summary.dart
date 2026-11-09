import '../../appointments/data/models/appointment.dart';
import '../../patients/data/doctor_patient.dart';

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

/// Which of [today] (earliest first, as [todaysAppointments] gives them) the
/// doctor is in now or will see next: the first whose hour-long slot has not
/// ended. Null once the day's last one is over.
int? currentOrNextIndex(List<Appointment> today, DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  for (var i = 0; i < today.length; i++) {
    // Consultations are booked in one-hour blocks ending on the hour.
    final end = (today[i].hour + 1) * 60;
    if (end > minutes) return i;
  }
  return null;
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

/// Why one patient last came: the reason on their latest visit up to today,
/// or failing that the nearest earlier visit that gave one.
///
/// For someone not yet seen, the reason on their soonest open booking, so a
/// new patient's row still says what they booked for. Cancelled bookings
/// never count. [visits] should all be one patient's.
///
/// A consultation completed early keeps its later booked day, so taking the
/// latest booking by date gave a reason from the future, and the Patients
/// list and the profile broke ties on that day differently.
String? lastVisitReason(Iterable<Appointment> visits, DateTime now) {
  final today = _dayOf(now);
  int byWhen(Appointment a, Appointment b) {
    final c = _day(a)!.compareTo(_day(b)!);
    return c != 0 ? c : startMinutes(a).compareTo(startMinutes(b));
  }

  String? reasonOf(Appointment a) {
    final r = a.reason?.trim();
    return r == null || r.isEmpty ? null : r;
  }

  final dated = visits.where((a) => !_cancelled(a) && _day(a) != null);
  final had = dated.where((a) => !_day(a)!.isAfter(today)).toList()
    ..sort(byWhen);
  for (final a in had.reversed) {
    final r = reasonOf(a);
    if (r != null) return r;
  }
  final ahead = dated
      .where((a) => _day(a)!.isAfter(today) && a.status != 'completed')
      .toList()
    ..sort(byWhen);
  for (final a in ahead) {
    final r = reasonOf(a);
    if (r != null) return r;
  }
  return null;
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

/// Where a patient stands with the doctor, from their appointments alone.
///
/// The patients table in the design has a Status column ("Attention Needed",
/// "Monitored"). Nothing records a clinical status, so this says only what
/// the appointments do.
enum PatientStatus {
  /// A booking from them is waiting for the doctor to accept.
  awaitingAcceptance,

  /// They have an appointment today that is still on.
  visitToday,

  /// They have an appointment on a later day.
  upcomingVisit,

  /// Nothing ahead: they have only been seen.
  seen,
}

/// The [PatientStatus] of one patient, most pressing first.
PatientStatus patientStatus(
  List<Appointment> all,
  int patientId,
  DateTime now,
) {
  final today = _dayOf(now);
  var visitToday = false;
  var upcoming = false;
  for (final a in all) {
    if (a.patientId != patientId || _cancelled(a)) continue;
    final d = _day(a);
    if (d == null || d.isBefore(today)) continue;
    final open = a.status == 'scheduled' || a.status == 'rescheduled';
    if (!a.doctorAccepted && open) return PatientStatus.awaitingAcceptance;
    if (d == today && open) {
      visitToday = true;
    } else if (d.isAfter(today) && a.status != 'completed') {
      // A consultation already completed is not still to come, even when
      // its booked day is later (completed early).
      upcoming = true;
    }
  }
  if (visitToday) return PatientStatus.visitToday;
  if (upcoming) return PatientStatus.upcomingVisit;
  return PatientStatus.seen;
}

/// "Today", "Yesterday", "3 days ago", "2 weeks ago", "5 months ago" or
/// "2 years ago" for a past [day]; "—" when there is none.
///
/// Appointments carry a date, not a time, so this counts whole days.
String daysAgoLabel(DateTime? day, DateTime now) {
  if (day == null) return '—';
  final days = _dayOf(now).difference(_dayOf(day.toLocal())).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  String ago(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';
  if (days < 7) return ago(days, 'day');
  if (days < 30) return ago(days ~/ 7, 'week');
  if (days < 365) return ago(days ~/ 30, 'month');
  return ago(days ~/ 365, 'year');
}

/// Whether [patient] matches the top bar's search: every word of [query]
/// appears in their name, patient ID, last reason for a visit, email or
/// phone number. An empty query matches everyone.
bool patientMatches(DoctorPatient patient, String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final haystack = [
    patient.name,
    '${patient.id}',
    patient.lastReason ?? '',
    patient.email ?? '',
    patient.phone ?? '',
  ].join(' ').toLowerCase();
  return words.every(haystack.contains);
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

import '../../appointments/data/models/appointment.dart';

/// A patient as this doctor is entitled to see them.
///
/// There is no roster of "my patients" anywhere, by design. The SRS puts a
/// provider-maintained patient list under out-of-scope "Provider-Side /
/// Clinical Workflow Features (EHR Territory)", and names the reason: scope
/// creep beyond a patient-owned PHR into a provider-controlled EHR.
///
/// What it does say is that a patient's records become visible to a doctor
/// "according to the patient's wishes", and that "when the patient makes a
/// booking he is agreeing to share his medical records". The booking is the
/// consent. So this list is derived from the doctor's own appointments:
/// everyone who chose to book them, and nobody else.
class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.name,
    required this.visits,
    this.email,
    this.phone,
    this.lastSeen,
    this.lastReason,
    this.nextVisit,
    this.hasCompletedVisit = false,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;

  /// Their profile photo, or null when they have not set one.
  final String? avatarUrl;

  /// How many times they have booked this doctor.
  final int visits;

  /// The most recent appointment date, past or future.
  final DateTime? lastSeen;

  /// Why they came the last time they gave a reason.
  final String? lastReason;

  /// The next appointment still ahead of now, if any.
  final DateTime? nextVisit;

  /// True once at least one appointment has been completed, which is what
  /// makes this an established relationship rather than a pending booking.
  final bool hasCompletedVisit;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Collapses a doctor's appointments into the people behind them.
///
/// Appointments without a patient id are dropped: without one there is no
/// way to tell two people of the same name apart, and guessing would merge
/// two patients' histories, which is the one mistake worth avoiding here.
List<DoctorPatient> patientsFromAppointments(
  List<Appointment> appointments, {
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  final byPatient = <int, List<Appointment>>{};

  for (final appointment in appointments) {
    final id = appointment.patientId;
    if (id == null) continue;
    (byPatient[id] ??= []).add(appointment);
  }

  final patients = byPatient.entries.map((entry) {
    final visits = entry.value;

    DateTime? latest;
    DateTime? next;
    String? lastReason;
    String? email;
    String? phone;
    String? avatarUrl;
    var completed = false;

    for (final visit in visits) {
      if ((visit.status ?? '').toLowerCase() == 'completed') completed = true;
      email ??= _blankToNull(visit.patientEmail);
      phone ??= _blankToNull(visit.patientPhone);
      avatarUrl ??= _blankToNull(visit.patientAvatarUrl);

      final date = visit.date;
      if (date == null) continue;

      if (latest == null || date.isAfter(latest)) {
        latest = date;
        lastReason = _blankToNull(visit.reason) ?? lastReason;
      }
      // Only a visit still to happen is next: a completed or cancelled one
      // dated later is not (one completed early showed as the next visit).
      final status = (visit.status ?? '').toLowerCase();
      final open = status != 'completed' && status != 'cancelled';
      if (open &&
          date.isAfter(moment) &&
          (next == null || date.isBefore(next))) {
        next = date;
      }
    }

    // Any of the rows carries the name; prefer one that is not empty.
    final name = visits
            .map((v) => v.patientName.trim())
            .firstWhere((n) => n.isNotEmpty, orElse: () => '')
            .trim();

    return DoctorPatient(
      id: entry.key,
      name: name.isEmpty ? 'Unnamed patient' : name,
      email: email,
      phone: phone,
      visits: visits.length,
      lastSeen: latest,
      lastReason: lastReason,
      nextVisit: next,
      hasCompletedVisit: completed,
      avatarUrl: avatarUrl,
    );
  }).toList();

  // Most recently seen first; anyone with no dated appointment sinks to the
  // bottom rather than disappearing.
  patients.sort((a, b) {
    final left = a.lastSeen;
    final right = b.lastSeen;
    if (left == null && right == null) return a.name.compareTo(b.name);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });

  return patients;
}

String? _blankToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/dashboard/data/dashboard_summary.dart';

/// The dashboard's patients table shows a status and "last activity" worked
/// out from appointments, in place of the design's invented clinical
/// statuses.
final now = DateTime(2026, 11, 4, 9, 15);

Appointment appt(
  int patientId,
  DateTime date, {
  String status = 'scheduled',
  bool accepted = true,
}) =>
    Appointment(
      id: date.day * 100 + patientId,
      patientId: patientId,
      patientName: 'P$patientId',
      date: date,
      timeSlot: '10:00',
      status: status,
      doctorAccepted: accepted,
    );

void main() {
  group('patientStatus', () {
    test('a booking waiting to be accepted comes first', () {
      final list = [
        appt(1, DateTime(2026, 11, 4)),
        appt(1, DateTime(2026, 11, 10), accepted: false),
      ];
      expect(patientStatus(list, 1, now), PatientStatus.awaitingAcceptance);
    });

    test('an appointment still on today beats one later', () {
      final list = [
        appt(1, DateTime(2026, 11, 4)),
        appt(1, DateTime(2026, 11, 10)),
      ];
      expect(patientStatus(list, 1, now), PatientStatus.visitToday);
    });

    test("today's finished visit is not a visit today", () {
      final list = [appt(1, DateTime(2026, 11, 4), status: 'completed')];
      expect(patientStatus(list, 1, now), PatientStatus.seen);
    });

    test('a later appointment is an upcoming visit', () {
      final list = [
        appt(1, DateTime(2026, 10, 1), status: 'completed'),
        appt(1, DateTime(2026, 12, 1)),
      ];
      expect(patientStatus(list, 1, now), PatientStatus.upcomingVisit);
    });

    test('a later consultation already completed is not an upcoming visit',
        () {
      // Completed early: the booked day is ahead, but it has happened.
      final list = [appt(1, DateTime(2026, 11, 12), status: 'completed')];
      expect(patientStatus(list, 1, now), PatientStatus.seen);
      // Nor is it the last visit: that is the latest day up to today.
      expect(lastVisit(list, 1, now), isNull);
    });

    test('cancelled and past bookings, and other patients, do not count', () {
      final list = [
        appt(1, DateTime(2026, 12, 1), status: 'cancelled'),
        appt(1, DateTime(2026, 10, 1), accepted: false),
        appt(2, DateTime(2026, 11, 4), accepted: false),
      ];
      expect(patientStatus(list, 1, now), PatientStatus.seen);
    });
  });

  group('currentOrNextIndex', () {
    final today = [
      for (final slot in ['08:30', '09:45', '14:20'])
        Appointment(id: 1, patientName: 'P', timeSlot: slot, status: 'scheduled'),
    ];
    int? at(int h, int m) =>
        currentOrNextIndex(today, DateTime(2026, 11, 4, h, m));

    test('the one in progress, else the next, else none', () {
      expect(at(7, 0), 0, reason: 'before the first');
      expect(at(8, 50), 0, reason: 'the 08:30 slot runs to 09:00');
      expect(at(9, 0), 1);
      expect(at(12, 0), 2);
      expect(at(15, 0), isNull, reason: 'the day is over');
    });
  });

  group('daysAgoLabel', () {
    String label(DateTime? d) => daysAgoLabel(d, now);

    test('counts whole days, then weeks, months and years', () {
      expect(label(null), '—');
      expect(label(DateTime(2026, 11, 4)), 'Today');
      expect(label(DateTime(2026, 11, 3)), 'Yesterday');
      expect(label(DateTime(2026, 11, 1)), '3 days ago');
      expect(label(DateTime(2026, 10, 28)), '1 week ago');
      expect(label(DateTime(2026, 10, 14)), '3 weeks ago');
      expect(label(DateTime(2026, 8, 4)), '3 months ago');
      expect(label(DateTime(2024, 10, 1)), '2 years ago');
    });
  });
}

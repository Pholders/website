import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/patients/data/doctor_patient.dart';

Appointment appointment({
  required int id,
  int? patientId,
  String name = 'Thandi Mokoena',
  String? email,
  String? phone,
  DateTime? date,
  String? reason,
  String? status,
}) {
  return Appointment.fromJson({
    'id': id,
    'patientId': patientId,
    'patientName': name,
    'patientEmail': email,
    'patientPhone': phone,
    'appointmentDate': date?.toIso8601String(),
    'reason': reason,
    'status': status,
    'doctorAccepted': true,
  });
}

void main() {
  final now = DateTime(2026, 10, 15, 12);

  test('a patient appears because they booked, once per person', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 9, 1)),
      appointment(id: 2, patientId: 7, date: DateTime(2026, 10, 1)),
      appointment(id: 3, patientId: 9, name: 'Sipho Dube', date: DateTime(2026, 8, 1)),
    ], now: now);

    expect(list.length, 2);
    expect(list.map((p) => p.id), containsAll(<int>[7, 9]));
    expect(list.firstWhere((p) => p.id == 7).visits, 2);
  });

  test('nobody appears when the doctor has no appointments', () {
    expect(patientsFromAppointments(const [], now: now), isEmpty);
  });

  test('an appointment with no patient id is dropped rather than guessed at', () {
    // Two different people can share a name; merging them would join their
    // histories, which is the mistake worth avoiding.
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: null, name: 'Thandi Mokoena'),
      appointment(id: 2, patientId: 7, name: 'Thandi Mokoena'),
    ], now: now);

    expect(list.length, 1);
    expect(list.single.id, 7);
    expect(list.single.visits, 1);
  });

  test('the most recent appointment is the one reported as last seen', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 9, 1), reason: 'Chest pain'),
      appointment(id: 2, patientId: 7, date: DateTime(2026, 10, 1), reason: 'Follow-up'),
    ], now: now);

    expect(list.single.lastSeen, DateTime(2026, 10, 1));
    expect(list.single.lastReason, 'Follow-up');
  });

  test('an appointment still ahead is reported as the next visit', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 10, 1)),
      appointment(id: 2, patientId: 7, date: DateTime(2026, 11, 20)),
      appointment(id: 3, patientId: 7, date: DateTime(2026, 12, 25)),
    ], now: now);

    // The soonest one ahead, not the furthest.
    expect(list.single.nextVisit, DateTime(2026, 11, 20));
    expect(list.single.lastSeen, DateTime(2026, 12, 25));
  });

  test('a patient with only past visits has no next visit', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 1, 1)),
    ], now: now);
    expect(list.single.nextVisit, isNull);
  });

  test('a completed appointment marks an established relationship', () {
    final booked = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 11, 1), status: 'scheduled'),
    ], now: now);
    expect(booked.single.hasCompletedVisit, isFalse);

    final seen = patientsFromAppointments([
      appointment(id: 1, patientId: 7, date: DateTime(2026, 9, 1), status: 'completed'),
      appointment(id: 2, patientId: 7, date: DateTime(2026, 11, 1), status: 'scheduled'),
    ], now: now);
    expect(seen.single.hasCompletedVisit, isTrue);
  });

  test('contact details are taken from whichever booking carries them', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, email: '', phone: null, date: DateTime(2026, 9, 1)),
      appointment(
        id: 2,
        patientId: 7,
        email: 'thandi@example.test',
        phone: '0821234567',
        date: DateTime(2026, 10, 1),
      ),
    ], now: now);

    expect(list.single.email, 'thandi@example.test');
    expect(list.single.phone, '0821234567');
  });

  test('the list reads most recently seen first', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, name: 'Older', date: DateTime(2026, 1, 1)),
      appointment(id: 2, patientId: 8, name: 'Newer', date: DateTime(2026, 10, 1)),
      appointment(id: 3, patientId: 9, name: 'Middle', date: DateTime(2026, 5, 1)),
    ], now: now);

    expect(list.map((p) => p.name), ['Newer', 'Middle', 'Older']);
  });

  test('someone with no dated appointment sinks to the bottom, not out', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, name: 'Undated', date: null),
      appointment(id: 2, patientId: 8, name: 'Dated', date: DateTime(2026, 5, 1)),
    ], now: now);

    expect(list.map((p) => p.name), ['Dated', 'Undated']);
    expect(list.last.lastSeen, isNull);
  });

  test('a nameless booking still renders as something', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, name: '   ', date: DateTime(2026, 5, 1)),
    ], now: now);
    // Appointment.fromJson already substitutes this, so the row never shows
    // a blank where a name belongs.
    expect(list.single.name, 'Unknown patient');
    expect(list.single.initials, 'UP');
  });

  test('initials come from the first two names', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, name: 'thandi naledi mokoena', date: DateTime(2026, 5, 1)),
    ], now: now);
    expect(list.single.initials, 'TN');
  });
}

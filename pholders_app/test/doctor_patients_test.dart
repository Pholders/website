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

  test('the last reason is from the latest visit up to today', () {
    // A consultation completed early keeps its later booked day; its reason
    // is not the last one. Nor is a cancelled booking's.
    final list = patientsFromAppointments([
      appointment(
          id: 1, patientId: 7, date: DateTime(2026, 10, 10), reason: 'Rash'),
      appointment(
          id: 2,
          patientId: 7,
          date: DateTime(2026, 10, 12),
          reason: 'Cancelled one',
          status: 'cancelled'),
      appointment(
          id: 3,
          patientId: 7,
          date: DateTime(2026, 10, 20),
          reason: 'Done early',
          status: 'completed'),
    ], now: now);
    expect(list.single.lastReason, 'Rash');

    // Someone not yet seen shows what they booked for.
    final fresh = patientsFromAppointments([
      appointment(
          id: 4, patientId: 8, date: DateTime(2026, 10, 30), reason: 'Back pain'),
    ], now: now);
    expect(fresh.single.lastReason, 'Back pain');
  });

  test('a later booking already completed or cancelled is not the next visit',
      () {
    // Completed early: its booked day is still ahead, but it has happened.
    final list = patientsFromAppointments([
      appointment(
          id: 1, patientId: 7, date: DateTime(2026, 10, 20), status: 'completed'),
      appointment(
          id: 2, patientId: 7, date: DateTime(2026, 10, 22), status: 'cancelled'),
      appointment(
          id: 3, patientId: 7, date: DateTime(2026, 10, 30), status: 'scheduled'),
    ], now: now);
    expect(list.single.nextVisit, DateTime(2026, 10, 30));
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

  liveShapeTest();

  test('initials come from the first two names', () {
    final list = patientsFromAppointments([
      appointment(id: 1, patientId: 7, name: 'thandi naledi mokoena', date: DateTime(2026, 5, 1)),
    ], now: now);
    expect(list.single.initials, 'TN');
  });
}

/// The exact shape the live API returned on 16 October for a real booking,
/// so a change to the response is caught here rather than on the screen.
void liveShapeTest() {
  test('a real booking from the live API becomes one patient row', () {
    final live = Appointment.fromJson(const {
      'id': 41,
      'patientId': 18,
      'patientName': 'Naledi Khumalo',
      'patientEmail': 'pt.check@pholders.test',
      'patientPhone': '0845551234',
      'appointmentDate': '2026-10-19T00:00:00.000Z',
      'timePeriod': 'morning',
      'timeSlot': '10:00',
      'reason': 'Persistent cough for two weeks',
      'consultationFee': '450.00',
      'status': 'pending_payment',
      'doctorAccepted': false,
      'action': 'Ready to create prescription',
    });

    final patients =
        patientsFromAppointments([live], now: DateTime(2026, 10, 16));

    expect(patients, hasLength(1));
    final patient = patients.single;
    expect(patient.id, 18);
    expect(patient.name, 'Naledi Khumalo');
    expect(patient.email, 'pt.check@pholders.test');
    expect(patient.phone, '0845551234');
    expect(patient.visits, 1);
    expect(patient.lastReason, 'Persistent cough for two weeks');
    expect(patient.initials, 'NK');
    // Booked but not yet consulted, and the visit is still ahead.
    expect(patient.hasCompletedVisit, isFalse);
    expect(patient.nextVisit, isNotNull);
  });

  test("the patient's photo carries through from their bookings", () {
    final withPhoto = Appointment.fromJson({
      'id': 2,
      'patientId': 7,
      'patientName': 'Thandi Mokoena',
      'patientAvatarUrl': 'https://example.test/api/profile/avatars/p7.jpg',
      'appointmentDate': DateTime(2026, 10, 1).toIso8601String(),
    });
    final list = patientsFromAppointments(
        [appointment(id: 1, patientId: 7, date: DateTime(2026, 9, 1)), withPhoto],
        now: DateTime(2026, 10, 15, 12));
    expect(list.single.avatarUrl, 'https://example.test/api/profile/avatars/p7.jpg');
    expect(patientsFromAppointments([appointment(id: 3, patientId: 9)], now: DateTime(2026, 10, 15, 12))
        .single.avatarUrl, isNull);
  });
}

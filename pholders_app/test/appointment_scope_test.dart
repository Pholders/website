import 'package:flutter_test/flutter_test.dart';

import 'package:pholders_app/features/doctor/appointments/data/appointments_repository.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';

void main() {
  group('appointment scope', () {
    test('defaults to the whole diary, not the inbox', () {
      // The endpoint only ever returned unaccepted bookings, so accepting one
      // made it vanish from the doctor's day — and took with it the only way
      // to write a prescription against it.
      expect(const LoadAppointmentsAction().scope, AppointmentScope.all);
    });

    test('a caller can still ask for the inbox alone', () {
      expect(
        const LoadAppointmentsAction(scope: AppointmentScope.inbox).scope,
        AppointmentScope.inbox,
      );
    });

    test('scope names match what the backend accepts', () {
      // These go on the query string verbatim; the server 400s on anything else.
      expect(
        AppointmentScope.values.map((s) => s.name).toSet(),
        {'inbox', 'upcoming', 'all'},
      );
    });
  });

  group('Appointment.fromJson', () {
    Map<String, dynamic> row(Map<String, dynamic> extra) => {
          'id': 4,
          'patientName': 'Test Patient',
          'appointmentDate': '2026-10-08T00:00:00.000Z',
          'timeSlot': '09:00',
          'status': 'scheduled',
          ...extra,
        };

    test('reads the patientId the endpoint now returns', () {
      expect(Appointment.fromJson(row({'patientId': 15})).patientId, 15);
    });

    test('tolerates a backend that does not send one yet', () {
      expect(Appointment.fromJson(row({})).patientId, isNull);
    });

    test('an accepted appointment is marked as such', () {
      // With the wider scope these now appear in the list, and the card hides
      // its Accept button on this flag.
      expect(
        Appointment.fromJson(row({'doctorAccepted': true})).doctorAccepted,
        isTrue,
      );
    });
  });
}

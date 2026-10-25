import 'package:flutter_test/flutter_test.dart';

import 'package:pholders_app/features/auth/data/models/doctor.dart';

Map<String, dynamic> _profile(Map<String, dynamic> extra) => {
      'id': 3,
      'first_name': 'Pule',
      'last_name': 'Test',
      'email': 'doc@pholders.test',
      ...extra,
    };

void main() {
  group('medical aids on the doctor profile', () {
    test('reads the schemes the profile returns', () {
      final doctor = Doctor.fromJson(_profile({
        'medicalAids': [
          {'id': 1, 'name': 'Discovery Health Medical Scheme'},
          {'id': 4, 'name': 'Bonitas Medical Fund'},
        ],
      }));

      expect(doctor.medicalAids.map((s) => s.id), [1, 4]);
      expect(doctor.medicalAids.first.name, 'Discovery Health Medical Scheme');
    });

    test('a backend without the field gives an empty list, not a crash', () {
      expect(Doctor.fromJson(_profile({})).medicalAids, isEmpty);
    });

    test('ignores malformed entries rather than failing the whole profile', () {
      final doctor = Doctor.fromJson(_profile({
        'medicalAids': [
          {'id': 1, 'name': 'Discovery Health Medical Scheme'},
          'not an object',
          42,
        ],
      }));

      expect(doctor.medicalAids, hasLength(1));
    });

    test('an id arriving as a string still parses', () {
      // Other endpoints on this backend return ids as strings, so the parser
      // should not assume otherwise here.
      final doctor = Doctor.fromJson(_profile({
        'medicalAids': [
          {'id': '7', 'name': 'Profmed'},
        ],
      }));

      expect(doctor.medicalAids.single.id, 7);
    });

    test('two schemes with the same id and name are equal', () {
      // The picker compares by id, and the view model is rebuilt on every
      // store change, so value equality keeps it from thrashing.
      expect(
        const MedicalAidScheme(id: 1, name: 'Profmed'),
        const MedicalAidScheme(id: 1, name: 'Profmed'),
      );
    });
  });
}

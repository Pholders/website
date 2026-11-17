import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/features/public/data/models/qr_prescription.dart';

/// The shape `GET /prescriptions/qr/:token` returns under data.prescription.
Map<String, dynamic> _payload(Map<String, dynamic> extra) => {
      'id': 9,
      'prescriptionNumber': 'RX-1791451251578-160B3DA7',
      'prescriber': {
        'name': 'Pule Test',
        'hpcsa': 'MP-9911234',
        'phone': '0712345678',
      },
      'patient': {'name': 'Thandi Testpatient'},
      'diagnosis': 'Tension headache',
      'medicines': [
        {
          'name': 'Amoxicillin',
          'dosage': '500mg',
          'form': 'capsule',
          'quantity': 21,
          'frequency': 'three times daily',
          'route': 'oral',
        }
      ],
      'signature': {'status': 'signed', 'timestamp': '2026-10-08T09:20:51.578Z'},
      'createdAt': '2026-10-08T09:20:00.000Z',
      ...extra,
    };

void main() {
  group('QrPrescription', () {
    test('reads a signed prescription opened by QR', () {
      final p = QrPrescription.fromJson(_payload({}));

      expect(p.number, 'RX-1791451251578-160B3DA7');
      expect(p.prescriberName, 'Pule Test');
      expect(p.prescriberHpcsa, 'MP-9911234');
      expect(p.patientName, 'Thandi Testpatient');
      expect(p.isSigned, isTrue);
      expect(p.medicines.single.name, 'Amoxicillin');
      expect(p.medicines.single.detail,
          '500mg capsule · 21 · three times daily · oral');
    });

    test('an unsigned script is not presented as dispensable', () {
      final p = QrPrescription.fromJson(
        _payload({'signature': {'status': 'pending'}}),
      );
      expect(p.isSigned, isFalse);
    });

    test('a missing prescriber block does not crash the page', () {
      final p = QrPrescription.fromJson(_payload({'prescriber': null}));

      expect(p.prescriberName, isNull);
      expect(p.number, isNotEmpty);
    });

    test('a script with no medicines parses to an empty list', () {
      expect(QrPrescription.fromJson(_payload({'medicines': null})).medicines,
          isEmpty);
    });

    test('a medicine with only a name still renders', () {
      final m = QrMedicine.fromJson(const {'name': 'Paracetamol'});

      expect(m.name, 'Paracetamol');
      expect(m.detail, '', reason: 'an empty detail line is simply not shown');
    });

    test('a nameless medicine does not render blank', () {
      expect(QrMedicine.fromJson(const {}).name, 'Unnamed medicine');
    });
  });
}

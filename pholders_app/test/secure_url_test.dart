import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/network/secure_url.dart';

void main() {
  group('secureImageUrl', () {
    test('upgrades the stored doctor photo URL that would not load', () {
      expect(
        secureImageUrl(
          'http://backend-system-u8s2.onrender.com/api/users/doctor/profile-images/doctor_18_1.jpg',
        ),
        'https://backend-system-u8s2.onrender.com/api/users/doctor/profile-images/doctor_18_1.jpg',
      );
    });

    test('leaves an https URL exactly as it is', () {
      const url = 'https://backend-system-u8s2.onrender.com/api/profile/avatars/a.png';
      expect(secureImageUrl(url), url);
    });

    test('leaves localhost alone, where http is how it is served', () {
      const url = 'http://localhost:3000/api/users/doctor/profile-images/dev.jpg';
      expect(secureImageUrl(url), url);
    });

    test('leaves loopback addresses alone too', () {
      expect(
        secureImageUrl('http://127.0.0.1:8090/x.png'),
        'http://127.0.0.1:8090/x.png',
      );
    });

    test('does not mistake a host that merely starts with localhost', () {
      // localhost.example.com is a real remote host, not the loopback.
      expect(
        secureImageUrl('http://localhost.example.com/x.png'),
        'https://localhost.example.com/x.png',
      );
    });

    test('keeps the query string and fragment', () {
      expect(
        secureImageUrl('http://host.test/a.png?token=abc#frag'),
        'https://host.test/a.png?token=abc#frag',
      );
    });

    test('passes null and empty through untouched', () {
      expect(secureImageUrl(null), isNull);
      expect(secureImageUrl(''), '');
    });

    test('ignores anything that is not an http URL', () {
      expect(secureImageUrl('assets/doctors.png'), 'assets/doctors.png');
      expect(
        secureImageUrl('data:image/png;base64,iVBORw0KGgo='),
        'data:image/png;base64,iVBORw0KGgo=',
      );
    });
  });
}

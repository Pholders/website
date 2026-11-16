import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/pharmacy/settings/data/pharmacy_profile.dart';
import 'package:pholders_app/features/pharmacy/settings/presentation/pharmacy_details_page.dart';
import 'package:pholders_app/features/pharmacy/settings/presentation/pharmacy_personal_info_page.dart';
import 'package:pholders_app/features/pharmacy/settings/presentation/pharmacy_professional_page.dart';

/// Stands in for the server: keeps the record, so what a page saves is what
/// the next page to open reads.
class _FakeRepo implements PharmacyProfileRepository {
  _FakeRepo(this.record);

  final Map<String, dynamic> record;
  final saves = <Map<String, dynamic>>[];
  Object? failSaveWith;

  @override
  Future<PharmacyProfile> fetch() async => PharmacyProfile({...record});

  @override
  Future<PharmacyProfile> save(Map<String, dynamic> changes) async {
    if (failSaveWith != null) throw failSaveWith!;
    saves.add(changes);
    record.addAll(changes);
    return PharmacyProfile({...record});
  }
}

Map<String, dynamic> _live() => {
      // The shape the live server returned for the seed pharmacy.
      'id': 17,
      'pharmacy_name': 'Bryanston Central Pharmacy',
      'first_name': 'Alice',
      'last_name': 'Johnson',
      'email': 'seed.pharm1@seed.test',
      'phone': '+27110001001',
      'license_number': 'SEED-PHARM-0001',
      'city': 'Bryanston',
      'province': 'Gauteng',
      'address': '123 Main Street, Bryanston',
      'zip_code': '2191',
      'operating_hours': null,
      'delivery_available': true,
      'delivery_radius': '5.00',
      'website': null,
      'description': 'Full-service pharmacy',
      'is_24_hours': true,
      'status': 'active',
    };

Future<void> _show(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

Finder _field(String key) => find.byKey(ValueKey('pharmacy-field-$key'));

String _text(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(_field(key)).controller!.text;

void main() {
  group('opening hours as typed', () {
    test('a range, two ranges, or closed', () {
      expect(hoursFromText('08:00-18:00'), ['08:00-18:00']);
      expect(hoursFromText('08:00 - 13:00, 14:00-18:00'),
          ['08:00-13:00', '14:00-18:00']);
      expect(hoursFromText('Closed'), isEmpty);
      expect(hoursFromText(''), isEmpty);
    });

    test('something that is not a time is refused', () {
      expect(hoursFromText('8am to 6pm'), isNull);
      expect(hoursFromText('25:00-26:00'), isNull);
    });

    test('a closed day reads as Closed', () {
      expect(hoursToText(const []), 'Closed');
      expect(hoursToText(null), 'Closed');
      expect(hoursToText(const ['09:00-13:00']), '09:00-13:00');
    });
  });

  testWidgets('personal information shows the real pharmacist, not a sample',
      (tester) async {
    await _show(tester, PharmacyPersonalInfoPage(repository: _FakeRepo(_live())));

    expect(_text(tester, 'first_name'), 'Alice');
    expect(_text(tester, 'last_name'), 'Johnson');
    expect(_text(tester, 'email'), 'seed.pharm1@seed.test');
    expect(find.text('Sam'), findsNothing);
    // Nothing is offered that the server cannot keep.
    expect(find.text('Username'), findsNothing);
    expect(find.text('Gender'), findsNothing);
    expect(find.text('Upload Photo'), findsNothing);
  });

  testWidgets('a changed name is saved and is there on the next visit',
      (tester) async {
    final repo = _FakeRepo(_live());
    await _show(tester, PharmacyPersonalInfoPage(repository: repo));

    await tester.enterText(_field('first_name'), 'Alicia');
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();

    expect(repo.saves.single['first_name'], 'Alicia');
    // Email is shown, never sent: it changes elsewhere.
    expect(repo.saves.single.containsKey('email'), isFalse);

    // Like a refresh: a fresh page reads the server again.
    await tester.pumpWidget(const SizedBox());
    await _show(tester, PharmacyPersonalInfoPage(repository: repo));
    expect(_text(tester, 'first_name'), 'Alicia');
  });

  testWidgets('an empty required name is not sent', (tester) async {
    final repo = _FakeRepo(_live());
    await _show(tester, PharmacyPersonalInfoPage(repository: repo));
    await tester.enterText(_field('last_name'), '  ');
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();
    expect(find.text('Surname is needed'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets('a failed save says so instead of claiming it saved',
      (tester) async {
    final repo = _FakeRepo(_live())
      ..failSaveWith = const ApiException(message: 'city cannot be empty');
    await _show(tester, PharmacyDetailsPage(repository: repo));
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pump();
    expect(find.text('city cannot be empty'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('pharmacy details save the location; the licence is read only',
      (tester) async {
    final repo = _FakeRepo(_live());
    await _show(tester, PharmacyDetailsPage(repository: repo));

    expect(_text(tester, 'pharmacy_name'), 'Bryanston Central Pharmacy');
    expect(tester.widget<TextField>(find.descendant(
            of: _field('license_number'), matching: find.byType(TextField)))
        .readOnly, isTrue);

    await tester.enterText(_field('zip_code'), '2021');
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();

    final sent = repo.saves.single;
    expect(sent['zip_code'], '2021');
    expect(sent['city'], 'Bryanston');
    expect(sent.containsKey('license_number'), isFalse);
    expect(sent.containsKey('status'), isFalse);
  });

  testWidgets('hours are sent in the shape patients read', (tester) async {
    final repo = _FakeRepo(_live()..['is_24_hours'] = false);
    await _show(tester, PharmacyProfessionalPage(repository: repo));

    await tester.enterText(_field('hours-weekday'), '08:00-18:00');
    await tester.enterText(_field('hours-saturday'), '09:00-13:00');
    await tester.enterText(_field('hours-sunday'), 'Closed');
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();

    final hours = repo.saves.single['operating_hours'] as Map;
    expect(hours['monday'], ['08:00-18:00']);
    expect(hours['friday'], ['08:00-18:00']);
    expect(hours['saturday'], ['09:00-13:00']);
    expect(hours['sunday'], isEmpty);
    expect(repo.saves.single['delivery_available'], isTrue);
    expect(repo.saves.single['delivery_radius'], 5.0);
  });

  testWidgets('hours that are not times are not sent', (tester) async {
    final repo = _FakeRepo(_live());
    await _show(tester, PharmacyProfessionalPage(repository: repo));
    await tester.enterText(_field('hours-weekday'), '8 till late');
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use 24-hour times'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets('turning delivery off clears the radius', (tester) async {
    final repo = _FakeRepo(_live());
    await _show(tester, PharmacyProfessionalPage(repository: repo));
    expect(_text(tester, 'radius'), '5');

    await tester.tap(find.byKey(const ValueKey('pharmacy-switch-delivers')));
    await tester.pumpAndSettle();
    expect(_field('radius'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('pharmacy-save')));
    await tester.pumpAndSettle();

    expect(repo.saves.single['delivery_available'], isFalse);
    expect(repo.saves.single['delivery_radius'], isNull);
  });
}

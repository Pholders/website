import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/features/doctor/billing/data/billing_repository.dart';
import 'package:pholders_app/features/doctor/notifications/data/doctor_notifications_repository.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';

/// A merge on 2026-11-16 dropped three registrations, and Billing,
/// Notifications and every patient profile tab became a red error screen
/// ("BillingRepository is not registered inside GetIt"). Nothing failed until
/// someone opened those pages.
void main() {
  test('every type looked up with sl<...> is registered', () {
    final lookedUp = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m
          in RegExp(r'sl<([A-Z][A-Za-z0-9]*)>').allMatches(file.readAsStringSync())) {
        lookedUp.add(m.group(1)!);
      }
    }
    // The Redux store is registered in main.dart once it is built, and
    // `sl<T>` appears in a doc comment.
    lookedUp.removeAll({'Store', 'T'});

    final source = File('lib/core/di/service_locator.dart').readAsStringSync();
    final registered = {
      for (final m in RegExp(r'register(?:Lazy)?(?:Singleton|Factory)<([A-Za-z0-9]+)>')
          .allMatches(source))
        m.group(1)!,
    };

    expect(lookedUp.difference(registered), isEmpty,
        reason: 'looked up with sl<...> but not registered in setupServiceLocator');
  });

  test('the three doctor repositories that went missing are registered',
      () async {
    await sl.reset();
    await setupServiceLocator();
    expect(sl.isRegistered<BillingRepository>(), isTrue);
    expect(sl.isRegistered<DoctorNotificationsRepository>(), isTrue);
    expect(sl.isRegistered<PatientRecordRepository>(), isTrue);
    await sl.reset();
  });
}

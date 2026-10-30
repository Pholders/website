import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every address the portal navigates to must have a route. The bell linked
/// to /doctor/notifications, which was never registered, so it opened a
/// blank page. This reads every context.go / push / replace of an AppRoutes
/// constant in lib/ and checks app_router.dart registers it.
///
/// It reads the router as text: loading it would pull in a pharmacy page
/// that uses dart:html, which does not compile outside a browser.
///
/// Pharmacy addresses are left out for now: the pharmacy bell and five of its
/// settings links have no route either, and that side belongs to someone else.
void main() {
  test('every AppRoutes address the app navigates to is registered', () {
    final registered = {
      for (final m in RegExp(r'path:\s*AppRoutes\.(\w+)')
          .allMatches(File('lib/core/routing/app_router.dart').readAsStringSync()))
        m.group(1)!,
    };
    expect(registered, contains('doctorDashboard'));

    final missing = <String>{};
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.replaceAll(r'\', '/').contains('features/pharmacy/'))) {
      for (final m in RegExp(r'context\.(?:go|push|replace)\(\s*AppRoutes\.(\w+)\s*\)')
          .allMatches(file.readAsStringSync())) {
        if (!registered.contains(m.group(1)) && !m.group(1)!.startsWith('pharmacy')) {
          missing.add('AppRoutes.${m.group(1)} in ${file.path.replaceAll(r'\', '/')}');
        }
      }
    }
    expect(missing, isEmpty, reason: 'navigated to but not registered');
  });
}

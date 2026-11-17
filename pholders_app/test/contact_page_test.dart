import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/features/public/presentation/contact_page.dart';
import 'package:pholders_app/shared/constants/contact_emails.dart';

/// Contact replaces the "Support — To be implemented" placeholder. For now
/// it shows the support inbox alone.
void main() {
  late List<Uri> opened;
  late bool emailAppAnswers;

  Future<void> show(WidgetTester tester, Size size) async {
    opened = [];
    emailAppAnswers = true;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/contact', routes: [
      GoRoute(
        path: '/contact',
        builder: (_, __) => ContactPage(openEmail: (uri) async {
          opened.add(uri);
          return emailAppAnswers;
        }),
      ),
      GoRoute(path: '/login', builder: (_, __) => const Text('Login page')),
      GoRoute(
          path: '/how-it-works',
          builder: (_, __) => const Text('How it works page')),
      GoRoute(
          path: '/register', builder: (_, __) => const Text('Register page')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find.byType(Scrollable).first;

  testWidgets('only the support address is shown', (tester) async {
    await show(tester, const Size(1440, 1000));
    expect(find.text(ContactEmails.support), findsOneWidget);
    for (final other in ['hello@', 'doctors@', 'billing@', 'careers@']) {
      expect(find.textContaining(other), findsNothing);
    }
  });

  testWidgets('the address card writes an email to support', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Write an email'), 200,
        scrollable: scrollable());
    await tester.tap(find.text('Write an email'));
    await tester.pumpAndSettle();
    expect(opened.single, Uri.parse('mailto:${ContactEmails.support}'));
  });

  testWidgets('the form writes the email to support', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('Write the email'), 300,
        scrollable: scrollable());

    // Nothing to write yet: it asks rather than opening an empty email.
    await tester.tap(find.text('Write the email'));
    await tester.pumpAndSettle();
    expect(find.text('Tell us your name'), findsOneWidget);
    expect(opened, isEmpty);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name'), 'Thandi Nkosi');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'), 'How do I join?');
    await tester.tap(find.text('Write the email'));
    await tester.pumpAndSettle();

    final uri = opened.single;
    expect(uri.path, ContactEmails.support);
    expect(uri.query, contains('subject=Message%20from%20Thandi%20Nkosi'));
    expect(uri.query, contains('How%20do%20I%20join%3F'));
  });

  testWidgets('with no email app, it says where to write', (tester) async {
    await show(tester, const Size(1440, 1000));
    emailAppAnswers = false;
    await tester.scrollUntilVisible(find.text('Write an email'), 200,
        scrollable: scrollable());
    await tester.tap(find.text('Write an email'));
    await tester.pump();
    expect(find.text('No email app opened. Write to ${ContactEmails.support}'),
        findsOneWidget);
  });

  testWidgets('a help tile leads to its page', (tester) async {
    await show(tester, const Size(1440, 1000));
    await tester.scrollUntilVisible(find.text('How it works'), 200,
        scrollable: scrollable());
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('How it works page'), findsOneWidget);
  });

  testWidgets('it lays out on a phone', (tester) async {
    await show(tester, const Size(360, 780));
    expect(find.text(ContactEmails.support), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Write the email'), 400,
        scrollable: scrollable());
    expect(find.text('Write the email'), findsOneWidget);
  });

  test('a mailto link encodes spaces as %20, not +', () {
    final uri = mailtoUri('a@b.co', subject: 'Hi there', body: 'A & B');
    expect(uri.toString(), 'mailto:a@b.co?subject=Hi%20there&body=A%20%26%20B');
  });
}

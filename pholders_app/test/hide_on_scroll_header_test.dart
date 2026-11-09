import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/shared/widgets/hide_on_scroll_header.dart';

/// The public pages' navbar slides away while the page scrolls down and
/// comes back when it scrolls up.
void main() {
  late ScrollController page;

  Future<void> show(WidgetTester tester) async {
    page = ScrollController();
    addTearDown(page.dispose);
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HideOnScrollHeader(
          header: const SizedBox(height: 60, child: Text('Navbar')),
          body: SingleChildScrollView(
            controller: page,
            child: Column(
              children: [
                // A sideways row inside the page.
                SizedBox(
                  height: 80,
                  child: ListView(
                    key: const Key('row'),
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < 20; i++)
                        const SizedBox(width: 120, child: Text('Chip')),
                    ],
                  ),
                ),
                const SizedBox(height: 4000),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  /// Whether the header is on screen: its slide offset is back at zero.
  bool shown(WidgetTester tester) =>
      tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset ==
      Offset.zero;

  testWidgets('scrolling down hides it, scrolling up brings it back',
      (tester) async {
    await show(tester);
    expect(shown(tester), isTrue);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(shown(tester), isFalse);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(shown(tester), isTrue);
  });

  testWidgets('a hidden header lets clicks through to the page',
      (tester) async {
    await show(tester);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final ignore = tester.widget<IgnorePointer>(find
        .ancestor(
            of: find.byType(AnimatedSlide),
            matching: find.byType(IgnorePointer))
        .first);
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('near the top it always shows', (tester) async {
    await show(tester);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    page.jumpTo(30);
    await tester.pumpAndSettle();
    expect(shown(tester), isTrue);
  });

  testWidgets('a sideways row does not move it', (tester) async {
    await show(tester);
    await tester.drag(find.byKey(const Key('row')), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(shown(tester), isTrue);
  });
}

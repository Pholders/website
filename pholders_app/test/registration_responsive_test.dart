import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/features/auth/presentation/widgets/signup_panel.dart';
import 'package:pholders_app/shared/theme/app_theme.dart';
import 'package:redux/redux.dart';

void main() {
  late Store<AppState> store;

  Future<void> showSignup(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    store = Store<AppState>(appReducer, initialState: AppState.initial());
    await tester.pumpWidget(StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SignupPanel(
              compact: viewport.width < AppTheme.mobileBreakpoint,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fillPersonalDetails(WidgetTester tester) async {
    const details = {
      'First name': 'Thandi',
      'Last name': 'Nkosi',
      'Phone number': '0821234567',
      'Email address': 'thandi@example.com',
      'Password': 'Str0ng!pass',
      'Confirm password': 'Str0ng!pass',
    };

    for (final entry in details.entries) {
      final input = field(entry.key);
      await tester.ensureVisible(input);
      await tester.enterText(input, entry.value);
    }
    await tester.pumpAndSettle();
  }

  for (final viewport in [
    const Size(390, 844),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 600),
    const Size(1440, 900),
    const Size(2560, 1440),
  ]) {
    testWidgets('SignupPanel advances inline at $viewport', (tester) async {
      await showSignup(tester, viewport);
      expect(tester.takeException(), isNull);
      await fillPersonalDetails(tester);
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Tell us about your practice'), findsOneWidget);
      expect(
        find.textContaining('Thandi, one more step after this'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Create account'));
      expect(find.text('Create account').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final viewport in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets(
        'inline practice dropdowns follow the selected province at $viewport',
        (tester) async {
      await showSignup(tester, viewport);
      await fillPersonalDetails(tester);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      var dropdowns = find.byType(DropdownButtonFormField<String>);
      var province = dropdowns.at(0);
      var city = dropdowns.at(1);
      expect(tester.widget<DropdownButtonFormField<String>>(city).onChanged,
          isNull);

      await tester.ensureVisible(province);
      await tester.tap(province);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gauteng').last);
      await tester.pumpAndSettle();

      dropdowns = find.byType(DropdownButtonFormField<String>);
      province = dropdowns.at(0);
      city = dropdowns.at(1);
      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Johannesburg').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(city).initialValue,
        'Johannesburg',
      );

      await tester.ensureVisible(province);
      await tester.tap(province);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Free State').last);
      await tester.pumpAndSettle();

      dropdowns = find.byType(DropdownButtonFormField<String>);
      city = dropdowns.at(1);
      expect(
        tester.widget<DropdownButtonFormField<String>>(city).initialValue,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

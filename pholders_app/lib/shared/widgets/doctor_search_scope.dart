import 'package:flutter/widgets.dart';

/// What the doctor has typed in the top bar's search, shared between the bar
/// and the page under it.
///
/// [ShellLayout] owns the query and puts this above both. The top bar only
/// shows its search field where a page reads the query — the dashboard,
/// whose patients table it filters — so there is never a box that searches
/// nothing.
class DoctorSearchScope extends InheritedNotifier<ValueNotifier<String>> {
  const DoctorSearchScope({
    super.key,
    required ValueNotifier<String> query,
    required super.child,
  }) : super(notifier: query);

  /// The shared query, or null outside a doctor shell.
  static ValueNotifier<String>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DoctorSearchScope>()
      ?.notifier;
}

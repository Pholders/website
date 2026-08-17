import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/shared/utils/greeting.dart';

void main() {
  test('timeOfDayGreeting covers each part of the day', () {
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 0)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 11, 59)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 12)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 16, 59)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 17)), 'Good Evening');
    expect(timeOfDayGreeting(DateTime(2026, 8, 11, 23, 59)), 'Good Evening');
  });
}

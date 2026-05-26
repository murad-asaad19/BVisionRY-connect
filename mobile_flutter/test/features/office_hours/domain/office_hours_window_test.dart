import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfficeHoursWindow', () {
    test('parses JSON from RPC settings.windows', () {
      final w = OfficeHoursWindow.fromJson(<String, dynamic>{
        'weekday': 1,
        'start_minute': 540,
        'end_minute': 720,
        'timezone': 'Europe/London',
      });
      expect(w.weekday, 1);
      expect(w.startMinute, 540);
      expect(w.endMinute, 720);
      expect(w.timezone, 'Europe/London');
    });

    test('toJson is symmetric and uses snake_case keys', () {
      const w = OfficeHoursWindow(
        weekday: 3,
        startMinute: 600,
        endMinute: 660,
        timezone: 'America/New_York',
      );
      expect(w.toJson(), <String, dynamic>{
        'weekday': 3,
        'start_minute': 600,
        'end_minute': 660,
        'timezone': 'America/New_York',
      });
    });

    test('weekdayName maps 0..6 to Sun..Sat (DB convention)', () {
      expect(OfficeHoursWindow.weekdayName(0), 'Sunday');
      expect(OfficeHoursWindow.weekdayName(1), 'Monday');
      expect(OfficeHoursWindow.weekdayName(2), 'Tuesday');
      expect(OfficeHoursWindow.weekdayName(3), 'Wednesday');
      expect(OfficeHoursWindow.weekdayName(4), 'Thursday');
      expect(OfficeHoursWindow.weekdayName(5), 'Friday');
      expect(OfficeHoursWindow.weekdayName(6), 'Saturday');
    });

    test('minute<->HH:MM converters round-trip', () {
      expect(OfficeHoursWindow.minuteToHhmm(0), '00:00');
      expect(OfficeHoursWindow.minuteToHhmm(540), '09:00');
      expect(OfficeHoursWindow.minuteToHhmm(1439), '23:59');
      expect(OfficeHoursWindow.hhmmToMinute('00:00'), 0);
      expect(OfficeHoursWindow.hhmmToMinute('09:00'), 540);
      expect(OfficeHoursWindow.hhmmToMinute('23:59'), 1439);
    });

    test('validate() returns null on a legal window', () {
      const w = OfficeHoursWindow(
        weekday: 1,
        startMinute: 540,
        endMinute: 720,
        timezone: 'UTC',
      );
      expect(w.validate(), isNull);
    });

    test('validate() rejects end <= start', () {
      const w = OfficeHoursWindow(
        weekday: 1,
        startMinute: 720,
        endMinute: 720,
        timezone: 'UTC',
      );
      expect(w.validate(), 'officeHours.settings.windowEndAfterStart');
    });

    test('validate() rejects out-of-range weekday', () {
      const w = OfficeHoursWindow(
        weekday: 7,
        startMinute: 0,
        endMinute: 60,
        timezone: 'UTC',
      );
      expect(w.validate(), isNotNull);
    });

    test('validate() rejects out-of-range minutes', () {
      const w = OfficeHoursWindow(
        weekday: 0,
        startMinute: -1,
        endMinute: 60,
        timezone: 'UTC',
      );
      expect(w.validate(), isNotNull);
    });

    test('validate() rejects empty timezone', () {
      const w = OfficeHoursWindow(
        weekday: 0,
        startMinute: 0,
        endMinute: 60,
        timezone: '',
      );
      expect(w.validate(), 'officeHours.settings.windowInvalidTimezone');
    });
  });
}

import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses my_office_hours_settings JSON shape', () {
    final s = OfficeHoursSettings.fromJson(<String, dynamic>{
      'user_id': 'a1',
      'enabled': true,
      'windows': <Map<String, dynamic>>[
        <String, dynamic>{
          'weekday': 1,
          'start_minute': 540,
          'end_minute': 720,
          'timezone': 'UTC',
        },
      ],
      'slot_duration_minutes': 30,
      'max_bookings_per_week': 5,
      'buffer_minutes': 10,
      'meeting_link_template': 'https://meet.example.com/{slot_id}',
      'notes_template': 'Bring an agenda.',
      'updated_at': '2026-05-25T10:00:00Z',
    });
    expect(s.userId, 'a1');
    expect(s.enabled, isTrue);
    expect(s.windows, hasLength(1));
    expect(s.slotDurationMinutes, 30);
    expect(s.maxBookingsPerWeek, 5);
    expect(s.bufferMinutes, 10);
    expect(s.meetingLinkTemplate, 'https://meet.example.com/{slot_id}');
    expect(s.notesTemplate, 'Bring an agenda.');
    expect(s.updatedAt, isNotNull);
    expect(s.updatedAt!.isUtc, isTrue);
  });

  test('OfficeHoursSettings.defaults matches spec defaults', () {
    final d = OfficeHoursSettings.defaults(userId: 'u1');
    expect(d.enabled, isFalse);
    expect(d.windows, isEmpty);
    expect(d.slotDurationMinutes, 15);
    expect(d.maxBookingsPerWeek, 5);
    expect(d.bufferMinutes, 5);
    expect(d.meetingLinkTemplate, isNull);
    expect(d.notesTemplate, isNull);
  });

  test('allowedSlotDurations is exactly {15, 30, 45, 60}', () {
    expect(OfficeHoursSettings.allowedSlotDurations, <int>[15, 30, 45, 60]);
  });

  test('validate() rejects slot duration outside allowed set', () {
    final bad = OfficeHoursSettings.defaults(userId: 'u')
        .copyWith(slotDurationMinutes: 20);
    expect(bad.validate(), 'officeHours.settings.invalidSlotDuration');
  });

  test('validate() rejects max bookings per week out of 1..50', () {
    final bad = OfficeHoursSettings.defaults(userId: 'u')
        .copyWith(maxBookingsPerWeek: 0);
    expect(bad.validate(), 'officeHours.settings.invalidMaxBookings');
    final bad2 = OfficeHoursSettings.defaults(userId: 'u')
        .copyWith(maxBookingsPerWeek: 51);
    expect(bad2.validate(), 'officeHours.settings.invalidMaxBookings');
  });

  test('validate() rejects buffer minutes out of 0..60', () {
    final bad = OfficeHoursSettings.defaults(userId: 'u')
        .copyWith(bufferMinutes: -1);
    expect(bad.validate(), 'officeHours.settings.invalidBuffer');
    final bad2 = OfficeHoursSettings.defaults(userId: 'u')
        .copyWith(bufferMinutes: 61);
    expect(bad2.validate(), 'officeHours.settings.invalidBuffer');
  });

  test('validate() rejects meeting_link_template missing https scheme', () {
    final bad = OfficeHoursSettings.defaults(userId: 'u').copyWith(
      enabled: true,
      meetingLinkTemplate: 'meet.example.com/{slot_id}',
    );
    expect(bad.validate(), 'officeHours.settings.meetingLinkHttpsRequired');
  });

  test('validate() ignores meetingLinkTemplate when disabled', () {
    final ok = OfficeHoursSettings.defaults(userId: 'u').copyWith(
      meetingLinkTemplate: 'meet.example.com/{slot_id}',
    );
    expect(ok.validate(), isNull);
  });

  test('validate() passes a clean enabled settings with one window', () {
    final ok = OfficeHoursSettings.defaults(userId: 'u').copyWith(
      enabled: true,
      windows: const <OfficeHoursWindow>[
        OfficeHoursWindow(
          weekday: 1,
          startMinute: 540,
          endMinute: 720,
          timezone: 'UTC',
        ),
      ],
      meetingLinkTemplate: 'https://meet.example.com/{slot_id}',
    );
    expect(ok.validate(), isNull);
  });
}

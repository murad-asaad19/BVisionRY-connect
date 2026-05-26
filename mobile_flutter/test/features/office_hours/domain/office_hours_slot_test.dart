import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses list_upcoming_slots row', () {
    final s = OfficeHoursSlot.fromJson(<String, dynamic>{
      'id': 's1',
      'host_id': 'h1',
      'starts_at': '2026-06-01T15:00:00Z',
      'ends_at': '2026-06-01T15:30:00Z',
      'status': 'open',
      'host_settings_notes_template': 'Prepare a 1-pager.',
    });
    expect(s.id, 's1');
    expect(s.hostId, 'h1');
    expect(s.status, SlotStatus.open);
    expect(s.startsAt.isUtc, isTrue);
    expect(s.durationMinutes, 30);
    expect(s.hostNotesTemplate, 'Prepare a 1-pager.');
  });

  test('SlotStatus.fromString maps all 3 db values', () {
    expect(SlotStatus.fromString('open'), SlotStatus.open);
    expect(SlotStatus.fromString('booked'), SlotStatus.booked);
    expect(SlotStatus.fromString('cancelled'), SlotStatus.cancelled);
  });

  test('SlotStatus.fromString throws on unknown value', () {
    expect(
      () => SlotStatus.fromString('rejected'),
      throwsA(isA<FormatException>()),
    );
  });
}

import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses my_bookings row', () {
    final b = MyBooking.fromJson(<String, dynamic>{
      'slot_id': 's1',
      'host_id': 'h1',
      'host_handle': 'rida',
      'host_name': 'Rida Garcia',
      'host_photo_url': 'https://avatars/r.png',
      'starts_at': '2026-06-01T15:00:00Z',
      'ends_at': '2026-06-01T15:30:00Z',
      'topic': 'Career advice',
      'meeting_proposal_id': 'mp1',
    });
    expect(b.slotId, 's1');
    expect(b.hostId, 'h1');
    expect(b.hostHandle, 'rida');
    expect(b.hostName, 'Rida Garcia');
    expect(b.topic, 'Career advice');
    expect(b.meetingProposalId, 'mp1');
    expect(b.durationMinutes, 30);
  });

  test('willReopenOnCancel true when starts > now + 24h', () {
    final now = DateTime.utc(2026, 6, 1, 0, 0);
    final b = MyBooking(
      slotId: 's',
      hostId: 'h',
      hostHandle: 'r',
      hostName: 'R',
      startsAt: now.add(const Duration(hours: 25)),
      endsAt: now.add(const Duration(hours: 26)),
    );
    expect(b.willReopenOnCancel(now: now), isTrue);
  });

  test('willReopenOnCancel false when starts within 24h', () {
    final now = DateTime.utc(2026, 6, 1, 0, 0);
    final b = MyBooking(
      slotId: 's',
      hostId: 'h',
      hostHandle: 'r',
      hostName: 'R',
      startsAt: now.add(const Duration(hours: 23)),
      endsAt: now.add(const Duration(hours: 24)),
    );
    expect(b.willReopenOnCancel(now: now), isFalse);
  });
}

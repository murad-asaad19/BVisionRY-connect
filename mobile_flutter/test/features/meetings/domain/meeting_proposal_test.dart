import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MeetingProposal.fromJson parses the canonical RPC row', () {
    final p = MeetingProposal.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'conversation_id': '22222222-2222-2222-2222-222222222222',
      'proposed_by_id': '33333333-3333-3333-3333-333333333333',
      'slots': ['2026-06-01T15:00:00Z', '2026-06-01T16:00:00Z'],
      'confirmed_slot': '2026-06-01T16:00:00Z',
      'duration_minutes': 30,
      'meeting_url': 'https://meet.google.com/abc-defg-hij',
      'timezone': 'America/New_York',
      'state': 'confirmed',
      'created_at': '2026-05-25T12:00:00Z',
      'updated_at': '2026-05-25T12:01:00Z',
    });
    expect(p.id, '11111111-1111-1111-1111-111111111111');
    expect(p.proposedById, '33333333-3333-3333-3333-333333333333');
    expect(p.slots, hasLength(2));
    expect(p.confirmedSlot?.toUtc().hour, 16);
    expect(p.durationMinutes, 30);
    expect(p.meetingUrl, 'https://meet.google.com/abc-defg-hij');
    expect(p.timezone, 'America/New_York');
    expect(p.state, MeetingState.confirmed);
  });

  test('isProposer returns true when proposedById matches viewerId', () {
    final p = _proposed(proposedBy: 'me');
    expect(p.isProposer('me'), isTrue);
    expect(p.isProposer('them'), isFalse);
  });

  test('hasEnded is true only when confirmed AND slot + duration < now', () {
    final past = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    final future = DateTime.now().toUtc().add(const Duration(hours: 2));
    final ended = _confirmed(slot: past, duration: 30);
    final upcoming = _confirmed(slot: future, duration: 30);
    expect(ended.hasEnded, isTrue);
    expect(upcoming.hasEnded, isFalse);
    expect(_proposed().hasEnded, isFalse);
  });
}

MeetingProposal _proposed({String proposedBy = 'p'}) => MeetingProposal(
      id: 'id',
      conversationId: 'cid',
      proposedById: proposedBy,
      slots: [DateTime.now().toUtc().add(const Duration(hours: 1))],
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.proposed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

MeetingProposal _confirmed({required DateTime slot, required int duration}) =>
    MeetingProposal(
      id: 'id',
      conversationId: 'cid',
      proposedById: 'p',
      slots: [slot],
      confirmedSlot: slot,
      durationMinutes: duration,
      timezone: 'UTC',
      state: MeetingState.confirmed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

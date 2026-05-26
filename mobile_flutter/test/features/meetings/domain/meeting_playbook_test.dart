import 'package:connect_mobile/features/meetings/domain/meeting_playbook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MeetingPlaybook.fromJson parses get_meeting_playbook row', () {
    final p = MeetingPlaybook.fromJson({
      'meeting_id': 'mid',
      'viewer_id': 'vid',
      'target_id': 'tid',
      'summary': 'Tara is a designer ...',
      'shared_interests': ['design systems', 'a11y', 'ux research'],
      'conversation_starters': ['Ask about ...', 'Mention ...', 'Compare ...'],
      'do_notes': ['Be specific', 'Ask thoughtful questions'],
      'dont_notes': ["Don't pitch"],
      'generated_at': '2026-05-25T11:00:00Z',
    });
    expect(p.summary, startsWith('Tara'));
    expect(p.sharedInterests, hasLength(3));
    expect(p.conversationStarters, hasLength(3));
    expect(p.doNotes, hasLength(2));
    expect(p.dontNotes, hasLength(1));
  });

  test('canRegenerate returns true after 1 hour past generated_at', () {
    final fresh = MeetingPlaybook(
      meetingId: 'm',
      viewerId: 'v',
      targetId: 't',
      summary: '',
      sharedInterests: const [],
      conversationStarters: const [],
      doNotes: const [],
      dontNotes: const [],
      generatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
    );
    final old = fresh.copyWith(
      generatedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    );
    expect(fresh.canRegenerate, isFalse);
    expect(old.canRegenerate, isTrue);
  });
}

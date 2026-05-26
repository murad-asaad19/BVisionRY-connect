import 'package:connect_mobile/features/meetings/data/meeting_playbook_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_playbook.dart';
import 'package:connect_mobile/features/meetings/providers/meeting_playbook_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements MeetingPlaybookService {}

void main() {
  test('meetingPlaybookProvider returns null when cache is empty', () async {
    final svc = _MockSvc();
    when(() => svc.fetchPlaybook(any())).thenAnswer((_) async => null);
    final container = ProviderContainer(
      overrides: [meetingPlaybookServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final result = await container.read(meetingPlaybookProvider('mid').future);
    expect(result, isNull);
  });

  test('meetingPlaybookProvider returns the cached row when present', () async {
    final svc = _MockSvc();
    final pb = MeetingPlaybook(
      meetingId: 'mid',
      viewerId: 'vid',
      targetId: 'tid',
      summary: 'about them',
      sharedInterests: const ['a'],
      conversationStarters: const ['b'],
      doNotes: const ['c'],
      dontNotes: const ['d'],
      generatedAt: DateTime.now().toUtc(),
    );
    when(() => svc.fetchPlaybook(any())).thenAnswer((_) async => pb);
    final container = ProviderContainer(
      overrides: [meetingPlaybookServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final result = await container.read(meetingPlaybookProvider('mid').future);
    expect(result, pb);
  });
}

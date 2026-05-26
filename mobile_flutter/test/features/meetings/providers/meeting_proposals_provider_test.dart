import 'package:connect_mobile/features/meetings/providers/meeting_proposals_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meetingProposalsProvider exposes a family by conversationId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(
      meetingProposalsProvider('conv-1'),
      (_, __) {},
    );
    expect(sub.read().isLoading, isTrue);
  });
}

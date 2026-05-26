import 'package:connect_mobile/features/meetings/providers/meeting_playbook_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meetingPlaybookProvider returns AsyncValue loading initially', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(meetingPlaybookProvider('mid'), (_, __) {});
    expect(sub.read().isLoading, isTrue);
  });
}

import 'package:connect_mobile/features/meetings/providers/pending_reviews_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pendingMeetingReviewsProvider returns AsyncValue loading initially',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(
      pendingMeetingReviewsProvider('conv-1'),
      (_, __) {},
    );
    expect(sub.read().isLoading, isTrue);
  });
}

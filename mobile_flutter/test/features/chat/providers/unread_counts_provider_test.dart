import 'package:connect_mobile/features/chat/data/chat_service.dart';
import 'package:connect_mobile/features/chat/providers/unread_counts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements ChatService {}

void main() {
  test('returns map of conversationId -> count', () async {
    final svc = _MockSvc();
    when(svc.listConversationUnread).thenAnswer(
      (_) async => [
        (conversationId: 'c1', unreadCount: 3),
        (conversationId: 'c2', unreadCount: 0),
        (conversationId: 'c3', unreadCount: 1),
      ],
    );
    final container = ProviderContainer(
      overrides: [chatServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final result = await container.read(unreadCountsProvider.future);
    expect(result['c1'], 3);
    expect(result['c2'], 0);
    expect(result['c3'], 1);
    expect(result.values.fold<int>(0, (a, b) => a + b), 4);
  });

  test('returns empty map when service returns no rows', () async {
    final svc = _MockSvc();
    when(svc.listConversationUnread).thenAnswer((_) async => []);
    final container = ProviderContainer(
      overrides: [chatServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final result = await container.read(unreadCountsProvider.future);
    expect(result, isEmpty);
  });
}

import 'dart:async';

import 'package:connect_mobile/features/chat/data/chat_service.dart';
import 'package:connect_mobile/features/chat/domain/conversation_overview.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/providers/conversation_overview_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements ChatService {}

ConversationOverview _row(String id) => ConversationOverview(
  conversationId: id,
  peerId: 'u2',
  peerName: 'A',
  peerHandle: 'a',
  lastMessageKind: MessageKind.text,
  lastMessageAt: DateTime.utc(2026, 5, 25, 10),
  unreadCount: 0,
  isMuted: false,
);

void main() {
  test('returns parsed overviews from RPC', () async {
    final svc = _MockSvc();
    when(svc.listConversationOverview).thenAnswer((_) async => [_row('c1')]);
    final controller = StreamController<void>.broadcast();
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(svc),
        messageStreamProvider.overrideWith((ref) => controller.stream),
      ],
    );
    addTearDown(() async {
      await controller.close();
      container.dispose();
    });
    final result = await container.read(conversationOverviewProvider.future);
    expect(result.first.conversationId, 'c1');
  });

  test('invalidates self when message stream fires', () async {
    final svc = _MockSvc();
    var calls = 0;
    when(svc.listConversationOverview).thenAnswer((_) async {
      calls++;
      return <ConversationOverview>[];
    });
    final controller = StreamController<void>.broadcast();
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(svc),
        messageStreamProvider.overrideWith((ref) => controller.stream),
      ],
    );
    addTearDown(() async {
      await controller.close();
      container.dispose();
    });
    await container.read(conversationOverviewProvider.future);
    expect(calls, 1);
    // Subscribe so the provider stays alive and the ref.listen runs.
    final sub = container.listen(conversationOverviewProvider, (_, __) {});
    controller.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(conversationOverviewProvider.future);
    expect(calls, 2);
    sub.close();
  });
}
